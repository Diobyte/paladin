---@diagnostic disable: undefined-global, undefined-field
local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local max_spell_range = 15.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_main_bool_base")),
    targeting_mode      = my_utility.safe_combo_box(0,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_targeting_mode")),

    advanced_tree       = my_utility.safe_tree_tab(2),
    priority_target     = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_priority_target")),
    min_target_range    = my_utility.safe_slider_float(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_min_target_range")),
    elites_only         = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_elites_only")),
    use_smart_aoe       = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_use_smart_aoe")),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 5.0, 0.1,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_custom_cooldown_sec")),
    debug_mode          = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Spear of the Heavens") then
        menu_elements.main_boolean:render("Enable Spear of the Heavens", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)

            if menu_elements.advanced_tree:push("Advanced Settings") then
                menu_elements.priority_target:render("Priority Targeting (Ignore weighted targeting)",
                    "Targets Boss > Champion > Elite > Any")
                menu_elements.min_target_range:render("Min Target Distance",
                    "Minimum distance to target to allow casting", 1)
                menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
                menu_elements.use_smart_aoe:render("Smart AOE Targeting",
                    "Target best cluster of enemies instead of single target")
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
            my_utility.debug_print("[SPEAR OF THE HEAVENS DEBUG] No target provided")
        end
        return false
    end;

    -- Handle priority targeting mode
    if menu_elements.priority_target:get() and target_selector_data then
        local priority_target = my_target_selector.get_priority_target(target_selector_data)
        if priority_target and my_utility.is_in_range(priority_target, max_spell_range) then
            target = priority_target
            if menu_elements.debug_mode:get() then
                my_utility.debug_print(
                    "[SPEAR OF THE HEAVENS DEBUG] Priority targeting enabled - using priority target: " ..
                    (target:get_skin_name() or "Unknown"))
            end
        else
            if menu_elements.debug_mode:get() then
                my_utility.debug_print(
                    "[SPEAR OF THE HEAVENS DEBUG] No valid priority target in range, using original target")
            end
        end
    end

    if menu_elements.elites_only:get() and not target:is_elite() then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[SPEAR OF THE HEAVENS DEBUG] Elites only mode - target is not elite")
        end
        return false
    end

    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.spear_of_the_heavens.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[SPEAR OF THE HEAVENS DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    local cast_position = target:get_position()
    local player_position = get_player_position()

    -- Smart AOE Logic
    if menu_elements.use_smart_aoe:get() then
        local radius = spell_data.spear_of_the_heavens.data.radius
        local area_data = target_selector.get_most_hits_target_circular_area_heavy(player_position, max_spell_range,
            radius)

        if area_data and area_data.n_hits > 1 and area_data.main_target then
            local best_point_data = my_utility.get_best_point(area_data.main_target:get_position(), radius,
                area_data.victim_list)
            if best_point_data and best_point_data.point then
                cast_position = best_point_data.point
                if menu_elements.debug_mode:get() then
                    my_utility.debug_print("[SPEAR OF THE HEAVENS DEBUG] Smart AOE active - Hits: " .. area_data.n_hits)
                end
            end
        end
    end

    local distance_sqr = cast_position:squared_dist_to_ignore_z(player_position)
    local min_range = menu_elements.min_target_range:get()
    local max_range_sqr = max_spell_range * max_spell_range
    local min_range_sqr = min_range * min_range

    if distance_sqr > max_range_sqr or distance_sqr < min_range_sqr then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[SPEAR OF THE HEAVENS DEBUG] Target/Position not in valid range")
        end
        return false
    end

    local cast_ok, delay = my_utility.try_cast_spell("spear_of_the_heavens", spell_data.spear_of_the_heavens.spell_id,
        menu_boolean, next_time_allowed_cast, function()
            return cast_spell.position(spell_data.spear_of_the_heavens.spell_id, cast_position,
                spell_data.spear_of_the_heavens.cast_delay)
        end, spell_data.spear_of_the_heavens.cast_delay)
    if cast_ok then
        local current_time = get_time_since_inject();
        local d = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or
            ((type(delay) == 'number') and delay or tonumber(spell_data.spear_of_the_heavens.cast_delay) or 0.1)
        next_time_allowed_cast = current_time + d;
        my_utility.debug_print("Cast Spear of the Heavens - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
        return true, d
    end

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[SPEAR OF THE HEAVENS DEBUG] Cast failed")
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
