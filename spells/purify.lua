local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0 -- Self-cast
local menu_elements =
{
    tree_tab     = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash(my_utility.plugin_label .. "purify_main_bool_base")),
    cast_delay   = slider_float:new(0.01, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "purify_cast_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Purify") then
        menu_elements.main_boolean:render("Enable Purify", "Cleansing ultimate that removes debuffs and heals")
        menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    -- Purify is a self-cast cleansing/healing skill - doesn't need a target
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_data.purify
    .spell_id);
    if not is_logic_allowed then return false end;

    local cast_ok, delay = my_utility.try_cast_spell("purify", spell_data.purify.spell_id, menu_boolean,
        next_time_allowed_cast, function()
        return cast_spell.self(spell_data.purify.spell_id, 0)
    end, menu_elements.cast_delay:get())
    if cast_ok then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + (delay or menu_elements.cast_delay:get());
        my_utility.debug_print("Cast Purify - Cleansing Activated");
        return true;
    end

    return false;
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
