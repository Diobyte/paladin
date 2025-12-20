local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0 -- Self-cast
local menu_elements =
{
    tree_tab     = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash(my_utility.plugin_label .. "aegis_main_bool_base")),
    hp_threshold = slider_float:new(0.0, 1.0, 0.5, get_hash(my_utility.plugin_label .. "aegis_hp_threshold")),
}

local function menu()
    if menu_elements.tree_tab:push("Aegis") then
        menu_elements.main_boolean:render("Enable Spell", "Defensive barrier ultimate that absorbs damage")

        if menu_elements.main_boolean:get() then
            menu_elements.hp_threshold:render("HP Threshold", "Cast when HP is below this percent (0.0 - 1.0)", 2)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    -- Aegis is a self-cast defensive barrier - doesn't need a target
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_data.aegis.spell_id);
    if not is_logic_allowed then return false end;

    local local_player = get_local_player();
    local current_hp_pct = local_player:get_current_health() / local_player:get_max_health();
    local hp_threshold = menu_elements.hp_threshold:get();

    if current_hp_pct > hp_threshold then
        return false;
    end

    local cast_ok, delay = my_utility.try_cast_spell("aegis", spell_data.aegis.spell_id, menu_boolean,
        next_time_allowed_cast, function()
        return cast_spell.self(spell_data.aegis.spell_id, 0)
    end, 0.1)

    if cast_ok then
        local current_time = get_time_since_inject();
        local cast_delay = delay or 0.1;
        next_time_allowed_cast = current_time + cast_delay;
        my_utility.debug_print("Cast Aegis - Defensive Barrier Activated");
        return true, cast_delay;
    end;

    return false;
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
