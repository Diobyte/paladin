local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
<<<<<<< Updated upstream
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "zenith_main_bool_base")),
    cast_delay          = slider_float:new(0.01, 10.0, 0.1,
=======
    tree_tab     = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash(my_utility.plugin_label .. "zenith_main_bool_base")),
    cast_delay   = slider_float:new(0.01, 10.0, 0.1,
>>>>>>> Stashed changes
        get_hash(my_utility.plugin_label .. "zenith_cast_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Zenith") then
<<<<<<< Updated upstream
        menu_elements.main_boolean:render("Enable Zenith", "")
<<<<<<< Updated upstream
        menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
=======
        if menu_elements.main_boolean:get() then
            menu_elements.min_enemy_count:render("Min Enemy Count", "Minimum number of enemies in range to cast", 1)
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
            menu_elements.is_independent:render("Independent Cast", "Cast independently of the rotation priority")
=======
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            -- Cast Settings
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
>>>>>>> Stashed changes
        end
>>>>>>> Stashed changes

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.zenith.spell_id);

    if not is_logic_allowed then return false end;

    if cast_spell.self(spell_data.zenith.spell_id, 0) then
        local current_time = get_time_since_inject();
        local cast_delay = menu_elements.cast_delay:get();
        next_time_allowed_cast = current_time + cast_delay;
        console.print("Cast Zenith");
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
