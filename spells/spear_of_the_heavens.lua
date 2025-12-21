local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 15.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab         = my_utility.safe_tree_tab(1),
    main_boolean     = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_main_bool_base")),
    targeting_mode   = my_utility.safe_combo_box(0,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_targeting_mode")),
    min_target_range = my_utility.safe_slider_float(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_min_target_range")),
    elites_only      = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_elites_only")),
    cast_delay       = my_utility.safe_slider_float(0.01, 1.0, 0.1,
        get_hash(my_utility.plugin_label .. "spear_of_the_heavens_cast_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Spear of the Heavens") then
        menu_elements.main_boolean:render("Enable Spear of the Heavens", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    if not target then return false end;
    if menu_elements.elites_only:get() and not target:is_elite() then return false end
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.spear_of_the_heavens.spell_id);

    if not is_logic_allowed then return false end;

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        return false
    end

    local cast_ok, delay = my_utility.try_cast_spell("spear_of_the_heavens", spell_data.spear_of_the_heavens.spell_id,
        menu_boolean, next_time_allowed_cast, function()
            return cast_spell.position(spell_data.spear_of_the_heavens.spell_id, target:get_position(), 0)
        end, menu_elements.cast_delay:get())
    if cast_ok then
        local current_time = get_time_since_inject();
        local d = (type(delay) == 'number') and delay or tonumber(menu_elements.cast_delay:get()) or 0.1
        next_time_allowed_cast = current_time + d;
        my_utility.debug_print("Cast Spear of the Heavens - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
        return true, d
    end

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type,
    set_next_time_allowed_cast = function(t) next_time_allowed_cast = t end
}
