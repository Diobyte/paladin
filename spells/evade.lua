---@diagnostic disable: undefined-global, undefined-field
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
    evade_mode          = my_utility.safe_combo_box(0, get_hash(my_utility.plugin_label .. "evade_mode_selector")),
    targeting_mode      = my_utility.safe_combo_box(0, get_hash(my_utility.plugin_label .. "evade_targeting_mode")),
    auto_dodge          = my_utility.safe_checkbox(true, get_hash(my_utility.plugin_label .. "evade_auto_dodge")),

    -- Advanced Settings Tree
    advanced_tree       = my_utility.safe_tree_tab(2),
    mobility_only       = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "evade_mobility_only")),
    min_target_range    = my_utility.safe_slider_float(3, max_spell_range - 1, 5,
        get_hash(my_utility.plugin_label .. "evade_min_target_range")),
    elites_only         = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "evade_elites_only")),
    min_travel_range    = my_utility.safe_slider_float(2.5, 5, 3,
        get_hash(my_utility.plugin_label .. "evade_min_travel_range")),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "evade_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 5.0, 0.5,
        get_hash(my_utility.plugin_label .. "evade_custom_cooldown_sec")),
    debug_mode          = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "evade_debug_mode")),
}

local evade_modes = { "Combat Only", "Combat & Travel" }

local function menu()
    if menu_elements.tree_tab:push("Evade") then
        menu_elements.main_boolean:render("Enable Evade", "")
        if menu_elements.main_boolean:get() then
            menu_elements.evade_mode:render("Evade Mode", evade_modes,
                "Combat Only: Dodge/Gap Close\nCombat & Travel: Also spam evade for movement out of combat")
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.auto_dodge:render("Auto-Dodge", "Automatically evade out of dangerous ground effects")

            if menu_elements.advanced_tree:push("Advanced Settings") then
                menu_elements.mobility_only:render("Only use for mobility", "")
                if menu_elements.mobility_only:get() then
                    menu_elements.min_target_range:render("Min Target Distance",
                        "Minimum distance to target to allow casting", 1)
                end
                menu_elements.elites_only:render("Elites Only", "Only cast on Elite/Boss enemies")

                if menu_elements.evade_mode:get() == 1 then
                    menu_elements.min_travel_range:render("Min Travel Distance",
                        "Minimum travel distance to use evade out of combat", 1)
                end

                menu_elements.use_custom_cooldown:render("Use Custom Cooldown",
                    "Override the base delay with a fixed value")
                if menu_elements.use_custom_cooldown:get() then
                    menu_elements.custom_cooldown_sec:render("Custom Cooldown (sec)",
                        "Set the custom cooldown in seconds",
                        2)
                end
                menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
                menu_elements.advanced_tree:pop()
            end
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
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[EVADE DEBUG] Still on cooldown")
        end
        return false
    end

    local is_logic_allowed = my_utility.is_spell_allowed(
        true, -- Always treat as enabled for paladin universal evade
        next_time_allowed_cast,
        spell_data.evade.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[EVADE DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    -- Auto-dodge logic: Check if current position is dangerous
    if menu_elements.auto_dodge:get() then
        local player_pos = get_player_position()
        if evade.is_dangerous_position(player_pos) then
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[EVADE DEBUG] Player in dangerous position! Finding safety...")
            end

            -- Try to find a safe position around the player
            local radius = 6.0 -- Evade distance
            local num_points = 8
            for i = 1, num_points do
                local angle = (i - 1) * (2 * math.pi / num_points)
                local test_pos = vec3.new(
                    player_pos:x() + radius * math.cos(angle),
                    player_pos:y() + radius * math.sin(angle),
                    player_pos:z()
                )

                if not evade.is_dangerous_position(test_pos) then
                    if cast_spell.position(spell_data.evade.spell_id, test_pos, spell_data.evade.cast_delay) then
                        local current_time = get_time_since_inject()
                        next_time_allowed_cast = current_time + 0.5
                        my_utility.debug_print("[EVADE] Auto-dodged to safety!")
                        return true, 0.5
                    end
                end
            end
        end
    end

    local mobility_only = menu_elements.mobility_only:get();

    -- Check if we have a valid target based on targeting mode
    if not target and not mobility_only and not (menu_elements.evade_mode:get() == 1) then
        -- No target found and out-of-combat usage not allowed
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[EVADE DEBUG] No target and out-of-combat not allowed")
        end
        return false -- Can't cast without a target in combat mode
    end

    if target and menu_elements.elites_only:get() and not (target:is_elite() or target:is_boss()) then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[EVADE DEBUG] Elites only mode - target is not elite or boss")
        end
        return false
    end

    local cast_position = nil
    if mobility_only then
        if target then
            if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
                if menu_elements.debug_mode:get() then
                    my_utility.debug_print("[EVADE DEBUG] Target not in valid range for mobility")
                end
                return false
            end
            cast_position = target:get_position()
        else
            -- For mobility without target, cast towards cursor
            local cursor_position = get_cursor_position()
            local player_position = get_player_position()
            if cursor_position:squared_dist_to_ignore_z(player_position) > max_spell_range * max_spell_range then
                if menu_elements.debug_mode:get() then
                    my_utility.debug_print("[EVADE DEBUG] Cursor too far for mobility cast")
                end
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
                    if menu_elements.debug_mode:get() then
                        my_utility.debug_print("[EVADE DEBUG] Not enough enemies for clustering: " .. enemy_count)
                    end
                    return false
                end
            end
            cast_position = target:get_position()
        else
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[EVADE DEBUG] No target for combat evade")
            end
            return false
        end
    end

    -- Cast the evade spell
    if cast_spell.position(spell_data.evade.spell_id, cast_position, spell_data.evade.cast_delay) then
        local current_time = get_time_since_inject();
        -- Enforce a minimum delay to prevent spamming. Use a smaller minimum when player-controlled
        -- for more responsive manual evades, and a larger minimum when auto-play is enabled to avoid spam.
        local user_delay = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or
            spell_data.evade.cast_delay;
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

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[EVADE DEBUG] Cast failed")
    end
    return false;
end

local function out_of_combat()
    -- Check if Orbwalker is active before allowing travel evade
    local ow = rawget(_G, "orbwalker")
    if type(ow) == "table" and type(ow.get_orb_mode) == "function" then
        if ow.get_orb_mode() == 0 then -- orb_mode.none
            return false
        end
    end

    -- Mode 1 is "Combat & Travel"
    local is_travel_mode = menu_elements.evade_mode:get() == 1;
    if not is_travel_mode then
        return false
    end

    -- Check if we are actually out of combat
    local enemies = actors_manager.get_enemy_actors()
    if #enemies > 0 then
        return false
    end

    -- Check if we are in a safezone
    local in_combat_area = my_utility.is_buff_active(spell_data.in_combat_area.spell_id,
        spell_data.in_combat_area.buff_id);
    if not in_combat_area then return false end;

    local local_player = get_local_player()
    local is_moving = local_player:is_moving()
    local is_dashing = local_player:is_dashing()

    -- if standing still
    if not is_moving then return false end;

    -- if not self play then we dont want to spam evade
    if is_dashing then return false end;

    -- Check minimum distance
    local player_position = get_player_position()
    local destination = local_player:get_move_destination()
    local distance_sqr = destination:squared_dist_to_ignore_z(player_position)
    local min_range = menu_elements.min_travel_range:get()
    if distance_sqr < min_range * min_range then
        return false
    end

    -- Cast towards destination
    if cast_spell.position(spell_data.evade.spell_id, destination, spell_data.evade.cast_delay) then
        local current_time = get_time_since_inject();
        local cooldown = 0.5; -- Fixed delay for out of combat
        next_time_allowed_cast = current_time + cooldown;
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[EVADE DEBUG] Cast out of combat evade")
        end
        return true, cooldown
    end

    return false
end

return
{
    menu = menu,
    logics = logics,
    out_of_combat = out_of_combat,
    menu_elements = menu_elements,
    -- Expose helper for tests to manipulate cooldown state
    set_next_time_allowed_cast = function(t) next_time_allowed_cast = t end
}
