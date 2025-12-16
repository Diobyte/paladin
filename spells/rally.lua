local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "rally_main_bool_base")),
}

local function menu()
    if menu_elements.tree_tab:push("Rally") then
        menu_elements.main_boolean:render("Enable Rally", "")

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.rally.spell_id);

    if not is_logic_allowed then return false end;

    -- Check if we already have the buff or cast it recently to save charges
    -- Rally duration is 8s. We want to refresh it only if it's about to expire or not active.
    -- However, is_buff_active might not be reliable for self-buffs depending on the API.
    -- Using the cache system to ensure we don't spam all 3 charges instantly.
    
    local current_time = get_time_since_inject()
    local last_cast = my_utility.get_last_cast_time("rally")
    
    -- Don't cast if we cast it less than 6 seconds ago (Duration is 8s)
    if current_time < last_cast + 6.0 then
        return false
    end

    if cast_spell.self(spell_data.rally.spell_id, 0) then
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        console.print("Cast Rally");
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
