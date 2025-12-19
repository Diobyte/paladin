local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 10.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "advance_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "advance_targeting_mode")),
    mobility_only       = checkbox:new(false, get_hash(my_utility.plugin_label .. "advance_mobility_only")),
    min_target_range    = slider_float:new(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "advance_min_target_range")),
    elites_only         = checkbox:new(false, get_hash(my_utility.plugin_label .. "advance_elites_only")),
    cast_delay          = slider_float:new(0.01, 1.0, 0.1, get_hash(my_utility.plugin_label .. "advance_cast_delay")),
    is_independent      = checkbox:new(false, get_hash(my_utility.plugin_label .. "advance_is_independent")),
}

local function menu()
    if menu_elements.tree_tab:push("Advance") then
        menu_elements.main_boolean:render("Enable Advance", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.mobility_only:render("Only use for mobility", "")
            if menu_elements.mobility_only:get() then
                menu_elements.min_target_range:render("Min Target Distance",
                    "\n     Must be lower than Max Targeting Range     \n\n", 1)
            end
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
            menu_elements.is_independent:render("Independent Cast", "Cast independently of the rotation priority")
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.advance.spell_id);

    if not is_logic_allowed then return false end;

    local mobility_only = menu_elements.mobility_only:get();
    
    -- Check if we have a valid target based on targeting mode
    if not target then
        -- No target found with current targeting mode
        if not mobility_only then
            return false  -- Can't cast without a target in combat mode
        end
    end
    
    if target and menu_elements.elites_only:get() and not target:is_elite() then return false end
    
    local cast_position = nil
    if mobility_only then
        if target then
            if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
                return false
            end
            cast_position = target:get_position()
        else
            -- For mobility without target, cast towards cursor
            local cursor_position = get_cursor_position()
            local player_position = get_player_position()
            
            -- Safety check: Don't dash into danger
            if evade.is_dangerous_position(cursor_position) then
                return false
            end

            if cursor_position:squared_dist_to_ignore_z(player_position) > max_spell_range * max_spell_range then
                return false  -- Cursor too far
            end
            cast_position = cursor_position
        end
    else
        -- Combat mode: require target
        if not target then return false end
        
        -- Defensive Logic: Dash AWAY if low HP
        local local_player = get_local_player()
        if local_player then
            local current_hp_pct = local_player:get_current_health() / local_player:get_max_health()
            if current_hp_pct < 0.3 then
                local player_pos = local_player:get_position()
                local target_pos = target:get_position()
                -- Calculate vector away from target
                local away_vector = (player_pos - target_pos):normalize()
                local safe_spot = player_pos + (away_vector * 5.0) -- Dash 5 yards away
                
                if not evade.is_dangerous_position(safe_spot) then
                    cast_position = safe_spot
                    console.print("Cast Advance - Defensive Dash Away")
                    if cast_spell.position(spell_data.advance.spell_id, cast_position, 0) then
                        local current_time = get_time_since_inject();
                        next_time_allowed_cast = current_time + menu_elements.cast_delay:get();
                        return true;
                    end
                end
            end
        end

        if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
            return false
        end
        cast_position = target:get_position()
    end

    if cast_spell.position(spell_data.advance.spell_id, cast_position, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + menu_elements.cast_delay:get();
        console.print("Cast Advance - Target: " ..
            (target and my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "None") ..
            ", Mobility: " .. tostring(mobility_only));
        return true;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type
}
