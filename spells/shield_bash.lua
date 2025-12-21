-- luacheck: globals cast_spell console prediction target_selector actors_manager
---@diagnostic disable: undefined-global, undefined-field
local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local max_spell_range = 15.0 -- Charge range
local menu_elements =
{
    tree_tab              = my_utility.safe_tree_tab(1),
    main_boolean          = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "shield_bash_main_bool_base")),
    targeting_mode        = my_utility.safe_combo_box(3,
        get_hash(my_utility.plugin_label .. "shield_bash_targeting_mode")),
    priority_target       = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "shield_bash_priority_target")),
    min_target_range      = my_utility.safe_slider_float(0.0, max_spell_range - 1, 0.0,
        get_hash(my_utility.plugin_label .. "shield_bash_min_target_range")),
    spam_with_intricacy   = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "shield_bash_spam_with_intricacy")),
    use_offensively       = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "shield_bash_use_offensively")),
    use_custom_cooldown   = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "shield_bash_use_custom_cooldown")),
    custom_cooldown_sec   = my_utility.safe_slider_float(0.1, 5.0, 0.1,
        get_hash(my_utility.plugin_label .. "shield_bash_custom_cooldown_sec")),
    filter_mode           = my_utility.safe_combo_box(1,
        get_hash(my_utility.plugin_label .. "shield_bash_offensive_filter")),
    enemy_count_threshold = my_utility.safe_slider_int(0, 30, 5,
        get_hash(my_utility.plugin_label .. "shield_bash_min_enemy_count")),
    evaluation_range      = my_utility.safe_slider_int(1, 16, 6,
        get_hash(my_utility.plugin_label .. "shield_bash_evaluation_range")),
    debug_mode            = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "shield_bash_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Shield Bash") then
        menu_elements.main_boolean:render("Enable Spell", "Charge at enemy and bash in front, dealing physical damage")

        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.priority_target:render("Priority Targeting (Ignore weighted targeting)",
                "Targets Boss > Champion > Elite > Any")
            menu_elements.min_target_range:render("Min Target Range", "Minimum distance to target to allow casting", 1)
            menu_elements.spam_with_intricacy:render("Spam with Intricacy", "")
            menu_elements.use_offensively:render("Use Offensively", "")

            menu_elements.use_custom_cooldown:render("Use Custom Cooldown",
                "Override the default cooldown with a custom value")
            if menu_elements.use_custom_cooldown:get() then
                menu_elements.custom_cooldown_sec:render("Custom Cooldown (sec)",
                    "Set the custom cooldown in seconds", 2)
            end

            if menu_elements.use_offensively:get() then
                menu_elements.evaluation_range:render("Evaluation Range", my_utility.evaluation_range_description)
                menu_elements.filter_mode:render("Filter Modes", my_utility.activation_filters, "")
                menu_elements.enemy_count_threshold:render("Minimum Enemy Count",
                    "Minimum number of enemies in Evaluation Range for spell activation")
            end

            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;
local CAST_DELAY = 0.1

local shield_bash_data = spell_data.shield_bash.data

local function logics(best_target, target_selector_data)
    -- Shield Bash requires a target to charge at
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast,
        spell_data.shield_bash.spell_id);
    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[SHIELD BASH DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    -- Precondition: requires a shield to be equipped
    if spell_data.shield_bash.requires_shield and not my_utility.has_shield() then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[SHIELD BASH DEBUG] Requires shield but no shield equipped")
        end
        return false
    end;

    -- Find target
    local target = best_target

    -- Handle priority targeting mode
    if menu_elements.priority_target:get() and target_selector_data then
        local priority_target = my_target_selector.get_priority_target(target_selector_data)
        if priority_target and my_utility.is_in_range(priority_target, max_spell_range) then
            target = priority_target
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[SHIELD BASH DEBUG] Priority targeting enabled - using priority target: " ..
                    (target:get_skin_name() or "Unknown"))
            end
        else
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[SHIELD BASH DEBUG] No valid priority target in range, using original target")
            end
            -- Fall back to original target
        end
    end

    if not target then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[SHIELD BASH DEBUG] No target provided")
        end
        return false
    end

    -- Check range
    local dist_sq = target:get_position():squared_dist_to_ignore_z(get_player_position())
    local min_range = menu_elements.min_target_range:get()

    if dist_sq > max_spell_range * max_spell_range then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[SHIELD BASH DEBUG] Target out of range")
        end
        return false
    end

    if dist_sq < min_range * min_range then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[SHIELD BASH DEBUG] Target too close")
        end
        return false -- Too close, don't charge
    end

    -- Check for wall collision
    local player_position = get_player_position()
    local target_position = target:get_position()
    if prediction.is_wall_collision(player_position, target_position, 1.0) then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[SHIELD BASH DEBUG] Wall collision detected")
        end
        return false
    end

    -- Offensive use logic
    local use_offensively = menu_elements.use_offensively:get()
    if use_offensively then
        local filter_mode = menu_elements.filter_mode:get()
        local evaluation_range = menu_elements.evaluation_range:get()
        local all_units_count, _, elite_units_count, champion_units_count, boss_units_count = my_utility
            .enemy_count_in_range(evaluation_range)

        local should_cast_offensive = (filter_mode == 1 and (elite_units_count >= 1 or champion_units_count >= 1 or boss_units_count >= 1))
            or (filter_mode == 2 and boss_units_count >= 1)
            or (all_units_count >= menu_elements.enemy_count_threshold:get())

        if not should_cast_offensive then
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[SHIELD BASH DEBUG] Offensive conditions not met")
            end
            return false
        end
    end

    local cast_ok, delay = my_utility.try_cast_spell("shield_bash", spell_data.shield_bash.spell_id, menu_boolean,
        next_time_allowed_cast, function()
            return cast_spell.target(target, spell_data.shield_bash.spell_id, 0, false)
        end, CAST_DELAY)
    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or
            (delay or CAST_DELAY);
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Shield Bash - Charged at enemy");
        return true, cooldown
    end

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[SHIELD BASH DEBUG] Cast failed")
    end
    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    set_next_time_allowed_cast = function(t) next_time_allowed_cast = t end
}
