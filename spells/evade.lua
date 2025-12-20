local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 10.0
local menu_elements =
{
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(true, get_hash(my_utility.plugin_label .. "evade_main_bool_base")),
    targeting_mode   = combo_box:new(0, get_hash(my_utility.plugin_label .. "evade_targeting_mode")),
    mobility_only    = checkbox:new(false, get_hash(my_utility.plugin_label .. "evade_mobility_only")),
    min_target_range = slider_float:new(0.0, max_spell_range - 1, 0.0,
        get_hash(my_utility.plugin_label .. "evade_min_target_range")),
    elites_only      = checkbox:new(false, get_hash(my_utility.plugin_label .. "evade_elites_only")),
    force_priority   = checkbox:new(true, get_hash(my_utility.plugin_label .. "evade_force_priority")),
}

local function menu()
    if menu_elements.tree_tab:push("Evade") then
        menu_elements.main_boolean:render("Enable Spell", "Enable Evade - In combat")

        if menu_elements.main_boolean:get() then
            -- Targeting
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Range", "Minimum distance to target to allow casting", 1)

            -- Logic
            menu_elements.mobility_only:render("Mobility Only", "Only use this spell for gap closing/mobility")
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite/Boss enemies")
            menu_elements.force_priority:render("Force Priority",
                "Always cast on Boss/Elite/Champion regardless of min range")
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
        spell_data.evade.spell_id);

    if not is_logic_allowed then return false end;

    local mobility_only = menu_elements.mobility_only:get();

    -- Check if we have a valid target based on targeting mode
    if not target then
        -- No target found with current targeting mode
        if not mobility_only then
            return false -- Can't cast without a target in combat mode
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
            return false
        end
    end

    -- Cast the evade spell
    if cast_spell.position(spell_data.evade.spell_id, cast_position, 0) then
        local current_time = get_time_since_inject();
        -- Enforce minimum delay to prevent spamming, especially with evade charge boots
        local min_delay = 0.5; -- Minimum 0.5 seconds between casts to prevent spam
        local actual_delay = min_delay;
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
