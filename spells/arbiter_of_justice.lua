---@diagnostic disable: undefined-global, undefined-field
local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local max_spell_range = 14.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "arbiter_of_justice_main_bool_base")),
    targeting_mode      = my_utility.safe_combo_box(0,
        get_hash(my_utility.plugin_label .. "arbiter_of_justice_targeting_mode")),

    advanced_tree       = my_utility.safe_tree_tab(2),
    priority_target     = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "arbiter_of_justice_priority_target")),
    min_target_range    = my_utility.safe_slider_float(0.0, max_spell_range - 1, 0.0,
        get_hash(my_utility.plugin_label .. "arbiter_of_justice_min_target_range")),
    min_hits            = my_utility.safe_slider_int(1, 20, 3,
        get_hash(my_utility.plugin_label .. "arbiter_of_justice_min_hits")),
    force_priority      = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "arbiter_of_justice_force_priority")),
    elites_only         = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "arbiter_of_justice_elites_only")),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "arbiter_of_justice_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 5.0, 0.1,
        get_hash(my_utility.plugin_label .. "arbiter_of_justice_custom_cooldown_sec")),
    debug_mode          = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "arbiter_of_justice_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Arbiter of Justice") then
        menu_elements.main_boolean:render("Enable Arbiter of Justice", "Enable or disable this spell")

        if menu_elements.main_boolean:get() then
            -- Targeting
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)

            if menu_elements.advanced_tree:push("Advanced Settings") then
                menu_elements.priority_target:render("Priority Targeting (Ignore weighted targeting)",
                    "Targets Boss > Champion > Elite > Any")
                menu_elements.min_target_range:render("Min Target Range",
                    "Minimum distance to target to allow casting (prevents casting too close)",
                    1)
                menu_elements.min_hits:render("Min Hits", "Minimum enemies required to trigger Smart AOE targeting", 1)

                -- Logic
                menu_elements.elites_only:render("Elites Only", "Only cast on Elite/Boss enemies")
                menu_elements.force_priority:render("Force Priority",
                    "Ignore Min Target Range for Boss/Elite/Champion targets")
                menu_elements.use_custom_cooldown:render("Use Custom Cooldown",
                    "Override the default cooldown with a custom value")
                if menu_elements.use_custom_cooldown:get() then
                    menu_elements.custom_cooldown_sec:render("Custom Cooldown (sec)",
                        "Set the custom cooldown in seconds", 2)
                end
                menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
                menu_elements.advanced_tree:pop()
            end
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target, target_selector_data)
    if not target then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ARBITER DEBUG] No target provided")
        end
        return false
    end;

    -- Handle priority targeting mode
    local cast_position = target:get_position()

    if menu_elements.priority_target:get() and target_selector_data then
        local priority_target = my_target_selector.get_priority_target(target_selector_data)
        if priority_target and my_utility.is_in_range(priority_target, max_spell_range) then
            target = priority_target
            cast_position = target:get_position()
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[ARBITER DEBUG] Priority targeting enabled - using priority target: " ..
                    (target:get_skin_name() or "Unknown"))
            end
        else
            if menu_elements.debug_mode:get() then
                my_utility.debug_print(
                    "[ARBITER DEBUG] Priority targeting enabled but no valid priority target in range, using original target")
            end
            -- Fall back to original target instead of returning false
        end
    elseif not menu_elements.priority_target:get() then
        -- Use AOE targeting if priority targeting is disabled
        local min_hits = menu_elements.min_hits:get()
        local player_pos = get_player_position()
        local aoe_data = my_target_selector.get_most_hits_circular(player_pos, max_spell_range, 5.0)

        if aoe_data.is_valid and aoe_data.hits_amount >= min_hits and aoe_data.main_target then
            target = aoe_data.main_target
            cast_position = target:get_position()

            -- Refine position using get_best_point
            local best_point_data = my_utility.get_best_point(cast_position, 5.0, aoe_data.victim_list)
            if best_point_data and best_point_data.point then
                cast_position = best_point_data.point
            end

            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[ARBITER DEBUG] Using AOE target with " .. aoe_data.hits_amount .. " hits")
            end
        end
    end

    if menu_elements.elites_only:get() and not target:is_elite() then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ARBITER DEBUG] Elites only mode - target is not elite")
        end
        return false
    end

    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.arbiter_of_justice.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ARBITER DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    if not my_utility.is_in_range(target, max_spell_range) then
        return false
    end

    local is_in_min_range = my_utility.is_in_range(target, menu_elements.min_target_range:get())
    local force_priority = menu_elements.force_priority:get()
    local is_priority = my_utility.is_high_priority_target(target)

    if is_in_min_range and not (force_priority and is_priority) then
        return false
    end

    local cast_ok, delay = my_utility.try_cast_spell("arbiter_of_justice", spell_data.arbiter_of_justice.spell_id,
        menu_boolean,
        next_time_allowed_cast,
        function()
            return cast_spell.position(spell_data.arbiter_of_justice.spell_id, cast_position,
                spell_data.arbiter_of_justice.cast_delay)
        end,
        spell_data.arbiter_of_justice.cast_delay)
    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = (delay or spell_data.arbiter_of_justice.cast_delay);

        if menu_elements.use_custom_cooldown:get() then
            cooldown = menu_elements.custom_cooldown_sec:get()
        end

        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Arbiter of Justice - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
        return true, cooldown;
    end

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[ARBITER DEBUG] Cast failed")
    end
    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type,
    set_next_time_allowed_cast = function(t) next_time_allowed_cast = t end
}
