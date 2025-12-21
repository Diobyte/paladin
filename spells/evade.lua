local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 10.0
-- NOTE: Evade uses a dynamic minimum delay to improve manual responsiveness:
--       when player-controlled (non auto-play) a smaller minimum delay is used
--       to allow quicker responsive evades; when auto-play is active a larger
--       minimum delay is enforced to avoid spamming.
local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true, get_hash(my_utility.plugin_label .. "evade_main_bool_base")),
    targeting_mode      = my_utility.safe_combo_box(0, get_hash(my_utility.plugin_label .. "evade_targeting_mode")),
    mobility_only       = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "evade_mobility_only")),
    min_target_range    = my_utility.safe_slider_float(3, max_spell_range - 1, 5,
        get_hash(my_utility.plugin_label .. "evade_min_target_range")),
    elites_only         = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "evade_elites_only")),
    allow_out_of_combat = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "evade_allow_out_of_combat")),
    cast_delay          = my_utility.safe_slider_float(0.01, 1.0, 0.1,
        get_hash(my_utility.plugin_label .. "evade_cast_delay")),
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
            menu_elements.cast_delay:render("Cast Delay",
                "Time between casts in seconds (min: 0.1s manual, 0.5s auto-play)", 2)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get();
    -- Evade is always enabled regardless of checkbox state for universal availability
    -- Extra local guard to enforce module-level next cast timing reliably
    local current_time_check = get_time_since_inject();
    if current_time_check < next_time_allowed_cast then
        -- still on module-enforced cooldown
        return false
    end

    local is_logic_allowed = my_utility.is_spell_allowed(
        true, -- Always treat as enabled for paladin universal evade
        next_time_allowed_cast,
        spell_data.evade.spell_id);

    if not is_logic_allowed then return false end;

    local mobility_only = menu_elements.mobility_only:get();

    -- Check if we have a valid target based on targeting mode
    if not target and not mobility_only and not menu_elements.allow_out_of_combat:get() then
        -- No target found and out-of-combat usage not allowed
        return false -- Can't cast without a target in combat mode
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
                return false -- Cursor too far
            end
            cast_position = cursor_position
        end
    else
        -- Check for enemy clustering for optimal positioning
        if target then
            local enemy_count = my_utility.enemy_count_simple(5) -- 5 yard range for clustering
            -- Always cast against elites/bosses or when we have good clustering
            if not (target:is_elite() or target:is_champion() or target:is_boss()) then
                if enemy_count < 1 then -- Minimum 1 enemies for non-elite (relaxed for general use)
                    return false
                end
            end
            cast_position = target:get_position()
        else
            -- If out of combat allowed, cast towards cursor when no target
            if menu_elements.allow_out_of_combat:get() then
                local enemies = actors_manager.get_enemy_actors()
                if #enemies == 0 then
                    local cursor_position = get_cursor_position()
                    local player_position = get_player_position()
                    if cursor_position:squared_dist_to_ignore_z(player_position) > max_spell_range * max_spell_range then
                        return false -- Cursor too far
                    end
                    cast_position = cursor_position
                else
                    return false
                end
            else
                return false
            end
        end
    end

    -- Cast the evade spell
    if cast_spell.position(spell_data.evade.spell_id, cast_position, 0) then
        local current_time = get_time_since_inject();
        -- Enforce a minimum delay to prevent spamming. Use a smaller minimum when player-controlled
        -- for more responsive manual evades, and a larger minimum when auto-play is enabled to avoid spam.
        local user_delay = menu_elements.cast_delay:get();
        local min_delay_auto = 0.5;   -- Minimum when auto-play is active
        local min_delay_manual = 0.1; -- Minimum when player-controlled
        local min_delay = my_utility.is_auto_play_enabled() and min_delay_auto or min_delay_manual
        local actual_delay = math.max(user_delay, min_delay);
        local ct = tonumber(current_time) or 0
        local ad = tonumber(actual_delay) or 0
        next_time_allowed_cast = ct + ad;
        my_utility.debug_print("Cast Evade (ID: " .. spell_data.evade.spell_id .. ") - Target: " ..
            (target and my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "None") ..
            ", Mobility: " ..
            tostring(mobility_only) ..
            ", AutoPlay: " ..
            tostring(my_utility.is_auto_play_enabled()) .. ", Delay: " .. string.format("%.2f", actual_delay) .. "s");
        return true, actual_delay;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    -- Expose helper for tests to manipulate cooldown state
    set_next_time_allowed_cast = function(t) next_time_allowed_cast = t end
}
