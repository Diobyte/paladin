local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements_paladin_evade =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "paladin_evade_main_bool")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "paladin_evade_targeting_mode")),
    mobility_only       = checkbox:new(false, get_hash(my_utility.plugin_label .. "paladin_evade_mobility_only")),
    min_target_range    = slider_float:new(3, 10.0 - 1, 5,
        get_hash(my_utility.plugin_label .. "paladin_evade_min_target_range")),
    debug_mode          = checkbox:new(false, get_hash(my_utility.plugin_label .. "paladin_evade_debug_mode")),
}

local function menu()
    if menu_elements_paladin_evade.tree_tab:push("Paladin Evade") then
        menu_elements_paladin_evade.main_boolean:render("Enable Paladin Evade", "Enhanced evade spell for paladins")
        if menu_elements_paladin_evade.main_boolean:get() then
            menu_elements_paladin_evade.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements_paladin_evade.mobility_only:render("Only use for mobility", "")
            if menu_elements_paladin_evade.mobility_only:get() then
                menu_elements_paladin_evade.min_target_range:render("Min Target Distance",
                    "\n     Must be lower than Max Targeting Range     \n\n", 1)
            end
            menu_elements_paladin_evade.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        end

        menu_elements_paladin_evade.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0.0;
local spell_id_paladin_evade = 2256888; -- The enhanced evade spell ID

local function logics(target)
    local menu_boolean = menu_elements_paladin_evade.main_boolean:get();
    local debug_enabled = menu_elements_paladin_evade.debug_mode:get();

    if debug_enabled then
        console.print("[PALADIN EVADE DEBUG] Starting logic check")
    end

    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_id_paladin_evade);

    if not is_logic_allowed then
        if debug_enabled then
            console.print("[PALADIN EVADE DEBUG] Logic not allowed")
        end
        return false
    end;

    local local_player = get_local_player()
    if not local_player then
        if debug_enabled then
            console.print("[PALADIN EVADE DEBUG] No local player")
        end
        return false
    end

    -- Check if player has the enhanced evade buff/enchantment
    -- This would be the condition that determines if paladin_evade is available
    local has_enhanced_evade = true -- For now, always available - could check buffs here

    if not has_enhanced_evade then
        if debug_enabled then
            console.print("[PALADIN EVADE DEBUG] Enhanced evade not available")
        end
        return false
    end

    if not local_player:is_spell_ready(spell_id_paladin_evade) then
        if debug_enabled then
            console.print("[PALADIN EVADE DEBUG] Spell not ready")
        end
        return false;
    end

    local mobility_only = menu_elements_paladin_evade.mobility_only:get();

    -- Check if we have a valid target based on targeting mode
    if not target then
        -- No target found with current targeting mode
        if not mobility_only then
            if debug_enabled then
                console.print("[PALADIN EVADE DEBUG] No target and not mobility only")
            end
            return false  -- Can't cast without a target in combat mode
        end
    end

    local cast_position = nil
    if mobility_only then
        if target then
            if not my_utility.is_in_range(target, 10.0) or my_utility.is_in_range(target, menu_elements_paladin_evade.min_target_range:get()) then
                if debug_enabled then
                    console.print("[PALADIN EVADE DEBUG] Target out of range for mobility")
                end
                return false
            end
            cast_position = target:get_position()
        else
            -- For mobility without target, cast towards cursor
            local cursor_position = get_cursor_position()
            local player_position = get_player_position()
            if cursor_position:squared_dist_to_ignore_z(player_position) > 10.0 * 10.0 then
                if debug_enabled then
                    console.print("[PALADIN EVADE DEBUG] Cursor too far")
                end
                return false  -- Cursor too far
            end
            cast_position = cursor_position
        end
    else
        -- Check for enemy clustering for optimal positioning
        if target then
            local enemy_count = my_utility.enemy_count_simple(5) -- 5 yard range for clustering
            -- Always cast against elites/bosses or when we have good clustering
            if not (target:is_elite() or target:is_champion() or target:is_boss()) then
                if enemy_count < 1 then  -- Minimum 1 enemies for non-elite (relaxed for general use)
                    if debug_enabled then
                        console.print("[PALADIN EVADE DEBUG] Not enough enemies for combat cast")
                    end
                    return false
                end
            end
            cast_position = target:get_position()
        else
            if debug_enabled then
                console.print("[PALADIN EVADE DEBUG] No target for combat cast")
            end
            return false
        end
    end

    -- Cast the enhanced evade spell
    if cast_spell.position(spell_id_paladin_evade, cast_position, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.instant_cast; -- Evade is instant

        if debug_enabled then
            console.print("[PALADIN EVADE DEBUG] Cast successful - Target: " ..
                (target and my_utility.targeting_modes[menu_elements_paladin_evade.targeting_mode:get() + 1] or "None") ..
                ", Mobility: " .. tostring(mobility_only));
        end
        return true;
    end;

    if debug_enabled then
        console.print("[PALADIN EVADE DEBUG] Cast failed")
    end
    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements_paladin_evade
}