local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 10.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(true, get_hash(my_utility.plugin_label .. "advance_main_bool_base")),
    targeting_mode   = combo_box:new(0, get_hash(my_utility.plugin_label .. "advance_targeting_mode")),
    mobility_only    = checkbox:new(false, get_hash(my_utility.plugin_label .. "advance_mobility_only")),
    min_target_range = slider_float:new(0.0, max_spell_range - 1, 0.0,
        get_hash(my_utility.plugin_label .. "advance_min_target_range")),
    max_faith        = slider_float:new(0.1, 1.0, 0.9, get_hash(my_utility.plugin_label .. "advance_max_faith")),
    force_priority   = checkbox:new(true, get_hash(my_utility.plugin_label .. "advance_force_priority")),
    elites_only      = checkbox:new(false, get_hash(my_utility.plugin_label .. "advance_elites_only")),
}

local function menu()
    if menu_elements.tree_tab:push("Advance") then
        menu_elements.main_boolean:render("Enable Spell", "Enable or disable this spell")

        if menu_elements.main_boolean:get() then
            -- Targeting
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Range", "Minimum distance to target to allow casting", 1)

            -- Logic
            menu_elements.max_faith:render("Max Faith %", "Don't cast if Faith is above this % (unless Mobility Only)", 1)
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
        spell_data.advance.spell_id);

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
    local force_priority = menu_elements.force_priority:get()
    local is_priority = target and my_utility.is_high_priority_target(target)

    if mobility_only then
        if target then
            if not my_utility.is_in_range(target, max_spell_range) then return false end

            local is_in_min_range = my_utility.is_in_range(target, menu_elements.min_target_range:get())
            if is_in_min_range and not (force_priority and is_priority) then
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
        -- Combat mode: require target
        if not target then return false end

        if not my_utility.is_in_range(target, max_spell_range) then return false end

        local local_player = get_local_player()
        local current_faith_pct = local_player:get_primary_resource_current() / local_player:get_primary_resource_max()
        local max_faith = menu_elements.max_faith:get()

        if current_faith_pct > max_faith and not (force_priority and is_priority) then
            return false
        end

        local is_in_min_range = my_utility.is_in_range(target, menu_elements.min_target_range:get())
        if is_in_min_range and not (force_priority and is_priority) then
            return false
        end
        cast_position = target:get_position()
    end

    local cast_delay = 0.1;
    local cast_ok, delay = my_utility.try_cast_spell("advance", spell_data.advance.spell_id, menu_boolean,
        next_time_allowed_cast, function()
            return cast_spell.position(spell_data.advance.spell_id, cast_position, 0)
        end, cast_delay)
    if cast_ok then
        local current_time = get_time_since_inject();
        local d = (type(delay) == 'number') and delay or tonumber(cast_delay) or 0.1
        print('DBG advance: current_time type=', type(current_time), 'value=', tostring(current_time), 'd type=', type(d),
            'value=', tostring(d))
        next_time_allowed_cast = current_time + d;
        my_utility.debug_print("Cast Advance - Target: " ..
            (target and my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "None") ..
            ", Mobility: " .. tostring(mobility_only));
        return true, (delay or cast_delay)
    end

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type
}
