local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0  -- Self-cast
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "fortress_main_bool_base")),
    cast_delay          = slider_float:new(0.01, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "fortress_cast_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Fortress") then
        menu_elements.main_boolean:render("Enable Fortress", "Create defensive area that grants immunity and resolve stacks")
        menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    -- Fortress is a self-cast fortification ultimate
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_data.fortress.spell_id);
    if not is_logic_allowed then return false end;

    if cast_spell.self(spell_data.fortress.spell_id, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + menu_elements.cast_delay:get();
        console.print("Cast Fortress - Defensive area activated");
        return true;
    end;

    return false;
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}