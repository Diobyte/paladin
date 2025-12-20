local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0
local menu_elements =
{
    tree_tab     = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash(my_utility.plugin_label .. "fanaticism_aura_main_bool_base")),
}

local function menu()
    if menu_elements.tree_tab:push("Fanaticism Aura") then
        menu_elements.main_boolean:render("Enable Spell", "Enable or disable this spell (Always maintains buff)")
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.fanaticism_aura.spell_id);

    if not is_logic_allowed then return false end;

    if cast_spell.self(spell_data.fanaticism_aura.spell_id, 0) then
        local current_time = get_time_since_inject();
        local cast_delay = 0.5;
        next_time_allowed_cast = current_time + cast_delay;
        console.print("Cast Fanaticism Aura");
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
