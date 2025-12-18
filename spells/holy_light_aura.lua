local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 15.0
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "holy_light_aura_main_bool_base")),
    cast_on_cooldown    = checkbox:new(false, get_hash(my_utility.plugin_label .. "holy_light_aura_cast_on_cooldown")),
    max_cast_range      = slider_float:new(1.0, 15.0, 5.0, get_hash(my_utility.plugin_label .. "holy_light_aura_max_cast_range")),
    cast_delay          = slider_float:new(0.01, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "holy_light_aura_cast_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Holy Light Aura") then
        menu_elements.main_boolean:render("Enable Holy Light Aura", "")
        if menu_elements.main_boolean:get() then
            menu_elements.cast_on_cooldown:render("Cast on Cooldown", "Always cast when ready (maintains buff constantly)")
            menu_elements.max_cast_range:render("Max Cast Range", "Only cast when enemies are within this range", 1)
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.holy_light_aura.spell_id);

    if not is_logic_allowed then return false end;

    -- Check if there are enemies within the specified range
    local enemy_count = my_utility.enemy_count_simple(menu_elements.max_cast_range:get());
    if enemy_count == 0 then return false end;

    -- Check cast on cooldown option
    if menu_elements.cast_on_cooldown:get() then
        -- Cast immediately when ready with minimal delay to maintain buff
        if cast_spell.self(spell_data.holy_light_aura.spell_id, 0) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + 0.1; -- Small delay to prevent spam
            console.print("Cast Holy Light Aura (On Cooldown)");
            return true;
        end;
        return false;
    end

    if cast_spell.self(spell_data.holy_light_aura.spell_id, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.holy_light_aura;
        console.print("Cast Holy Light Aura");
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
