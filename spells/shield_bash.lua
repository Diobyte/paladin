local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 15.0 -- Charge range
local menu_elements =
{
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(true, get_hash(my_utility.plugin_label .. "shield_bash_main_bool_base")),
    min_target_range = slider_float:new(0.0, max_spell_range - 1, 0.0,
        get_hash(my_utility.plugin_label .. "shield_bash_min_target_range")),
}

local function menu()
    if menu_elements.tree_tab:push("Shield Bash") then
        menu_elements.main_boolean:render("Enable Spell", "Charge at enemy and bash in front, dealing physical damage")

        if menu_elements.main_boolean:get() then
            menu_elements.min_target_range:render("Min Target Range", "Minimum distance to target to allow casting", 1)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;
local CAST_DELAY = 0.1

local function logics()
    -- Shield Bash requires a target to charge at
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast,
        spell_data.shield_bash.spell_id);
    if not is_logic_allowed then return false end;

    -- Precondition: requires a shield to be equipped
    if spell_data.shield_bash.requires_shield and not my_utility.has_shield() then
        return false
    end;

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

    local cast_ok, delay = my_utility.try_cast_spell("shield_bash", spell_data.shield_bash.spell_id, menu_boolean,
        next_time_allowed_cast, function()
            return cast_spell.target(target, spell_data.shield_bash.spell_id, 0, false)
        end, CAST_DELAY)
    if cast_ok then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + (delay or CAST_DELAY);
        my_utility.debug_print("Cast Shield Bash - Charged at enemy");
        return true, (delay or CAST_DELAY)
    end

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
