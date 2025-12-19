local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 10.0
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "evade_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "evade_targeting_mode")),
    mobility_only       = checkbox:new(false, get_hash(my_utility.plugin_label .. "evade_mobility_only")),
    min_target_range    = slider_float:new(3, max_spell_range - 1, 5,
        get_hash(my_utility.plugin_label .. "evade_min_target_range")),
    elites_only         = checkbox:new(false, get_hash(my_utility.plugin_label .. "evade_elites_only")),
    cast_delay          = slider_float:new(0.01, 1.0, 0.1, get_hash(my_utility.plugin_label .. "evade_cast_delay")),
    is_independent      = checkbox:new(false, get_hash(my_utility.plugin_label .. "evade_is_independent")),
    hp_threshold        = slider_float:new(0.0, 1.0, 0.35, get_hash(my_utility.plugin_label .. "evade_hp_threshold")),
    gap_close_only      = checkbox:new(true, get_hash(my_utility.plugin_label .. "evade_gap_close_only")),
    engage_distance     = slider_float:new(1.0, 10.0, 3.0, get_hash(my_utility.plugin_label .. "evade_engage_distance")),
}

local function menu()
    if menu_elements.tree_tab:push("Evade") then
        menu_elements.main_boolean:render("Enable Evade - In combat", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.mobility_only:render("Only use for mobility", "")
            if menu_elements.mobility_only:get() then
                menu_elements.min_target_range:render("Min Target Distance",
                    "\n     Must be lower than Max Targeting Range     \n\n", 1)
            end
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds (minimum 0.5s enforced)", 2)
            menu_elements.is_independent:render("Independent Cast", "Cast independently of the rotation priority")
            
            menu_elements.hp_threshold:render("Defensive HP Threshold", "Evade away from enemies if HP is below this %", 2)
            menu_elements.gap_close_only:render("Gap Close Only", "Only evade towards enemies if they are far away")
            if menu_elements.gap_close_only:get() then
                menu_elements.engage_distance:render("Engage Distance", "Minimum distance to enemy to trigger evade", 2)
            end
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    -- Evade is always enabled regardless of checkbox state for universal availability
    local is_logic_allowed = my_utility.is_spell_allowed(
        true,  -- Always treat as enabled for paladin universal evade
        next_time_allowed_cast,
        spell_data.evade.spell_id);

    if not is_logic_allowed then return false end;

    local local_player = get_local_player();
    if not local_player then return false end

    -- Defensive Logic (High Priority)
    local current_hp_pct = local_player:get_current_health() / local_player:get_max_health();
    if current_hp_pct < menu_elements.hp_threshold:get() then
        -- Evade away from target if exists, or cursor
        local cast_position = nil;
        if target then
            local player_pos = local_player:get_position();
            local target_pos = target:get_position();
            -- Vector from target to player
            local evade_vec = vec3:new(
                player_pos:x() - target_pos:x(),
                player_pos:y() - target_pos:y(),
                player_pos:z() - target_pos:z()
            ):normalize();
            
            -- Evade distance is roughly 5.0 units
            local evade_dist = 5.0
            local potential_pos = vec3:new(
                player_pos:x() + evade_vec:x() * evade_dist,
                player_pos:y() + evade_vec:y() * evade_dist,
                player_pos:z() + evade_vec:z() * evade_dist
            )
            
            -- Safety Check: Don't evade into danger
            if not evade.is_dangerous_position(potential_pos) then
                cast_position = potential_pos
            else
                -- If backward is dangerous, try sideways? For now, just don't cast to avoid suicide
                return false
            end
        else
            cast_position = get_cursor_position();
        end
        
        if cast_spell.position(spell_data.evade.spell_id, cast_position, 0) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + 0.5;
            console.print("Cast Evade (Defensive) - HP: " .. string.format("%.2f", current_hp_pct));
            return true;
        end
    end

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
            if cursor_position:squared_dist_to_ignore_z(player_position) > max_spell_range * max_spell_range then
                return false  -- Cursor too far
            end
            cast_position = cursor_position
        end
    else
        -- Combat Logic
        if target then
            local dist_sq = target:get_position():squared_dist_to_ignore_z(local_player:get_position());
            local engage_dist = menu_elements.engage_distance:get();
            
            if menu_elements.gap_close_only:get() then
                if dist_sq < engage_dist * engage_dist then
                    return false; -- Too close, don't waste evade
                end
            end
            
            cast_position = target:get_position()
        else
            return false
        end
    end

    -- Cast the evade spell
    if cast_spell.position(spell_data.evade.spell_id, cast_position, 0) then
        local current_time = get_time_since_inject();
        -- Enforce minimum delay to prevent spamming, especially with evade charge boots
        local user_delay = menu_elements.cast_delay:get();
        local min_delay = 0.5; -- Minimum 0.5 seconds between casts to prevent spam
        local actual_delay = math.max(user_delay, min_delay);
        next_time_allowed_cast = current_time + actual_delay;
        console.print("Cast Evade (ID: " .. spell_data.evade.spell_id .. ") - Target: " ..
            (target and my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "None") ..
            ", Mobility: " .. tostring(mobility_only) .. ", Delay: " .. string.format("%.2f", actual_delay) .. "s");
        return true;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}