local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 15.0 -- Charge range
local menu_elements =
{
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(true, get_hash(my_utility.plugin_label .. "shield_bash_main_bool_base")),
    min_target_range = slider_float:new(0, max_spell_range - 1, 2,
        get_hash(my_utility.plugin_label .. "shield_bash_min_target_range")),
    cast_delay       = slider_float:new(0.01, 1.0, 0.1, get_hash(my_utility.plugin_label .. "shield_bash_cast_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Shield Bash") then
        menu_elements.main_boolean:render("Enable Spell", "Charge at enemy and bash in front, dealing physical damage")

        if menu_elements.main_boolean:get() then
            menu_elements.min_target_range:render("Min Target Range", "Minimum distance to target to allow casting", 1)
            -- Cast Settings
            menu_elements.cast_delay:render("Cast Delay", "Time to wait after casting before taking another action", 2)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    -- Shield Bash requires a target to charge at
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast,
        spell_data.shield_bash.spell_id);
    if not is_logic_allowed then return false end;

    -- Find closest enemy target
    local target = target_selector.get_target_enemy(max_spell_range)
    if not target then return false end

    -- Check range
    local dist_sq = target:get_position():squared_dist_to_ignore_z(get_player_position())
    local min_range = menu_elements.min_target_range:get()

    if dist_sq > max_spell_range * max_spell_range then
        return false
    end

    if dist_sq < min_range * min_range then
        return false -- Too close, don't charge
    end

    -- Check for wall collision
    local player_position = get_player_position()
    local target_position = target:get_position()
    if prediction.is_wall_collision(player_position, target_position, 1.0) then
        return false
    end

    if cast_spell.target(target, spell_data.shield_bash.spell_id, 0, false) then
        local current_time = get_time_since_inject();
        local cast_delay = menu_elements.cast_delay:get();
        next_time_allowed_cast = current_time + cast_delay;
        console.print("Cast Shield Bash - Charged at enemy");
        return true, cast_delay;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
