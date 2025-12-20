local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 10.0
local targeting_type = "both"
local menu_elements =
{
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(true, get_hash(my_utility.plugin_label .. "paladin_evade_main_bool_base")),
    targeting_mode   = combo_box:new(0, get_hash(my_utility.plugin_label .. "paladin_evade_targeting_mode")),
    min_target_range = slider_float:new(3, max_spell_range - 1, 5,
        get_hash(my_utility.plugin_label .. "paladin_evade_min_target_range")),
    cast_delay       = slider_float:new(0.01, 1.0, 0.1, get_hash(my_utility.plugin_label .. "paladin_evade_cast_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Paladin Evade") then
        menu_elements.main_boolean:render("Enable Spell", "Enable or disable this spell")

        if menu_elements.main_boolean:get() then
            -- Targeting
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Range", "Minimum distance to target to allow casting", 1)

            -- Cast Settings
            menu_elements.cast_delay:render("Cast Delay", "Time to wait after casting before taking another action", 2)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    if not target then return false end;
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.paladin_evade.spell_id);

    if not is_logic_allowed then return false end;

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        return false
    end

    if cast_spell.position(spell_data.paladin_evade.spell_id, target:get_position(), 0) then
        local current_time = get_time_since_inject();
        local cast_delay = menu_elements.cast_delay:get();
        next_time_allowed_cast = current_time + cast_delay;
        console.print("Cast Paladin Evade");
        return true, cast_delay;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type
}
