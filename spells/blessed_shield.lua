local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 5.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "blessed_shield_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "blessed_shield_targeting_mode")),
    min_target_range    = slider_float:new(0, max_spell_range - 1, 0,
        get_hash(my_utility.plugin_label .. "blessed_shield_min_target_range")),
    elites_only         = checkbox:new(false, get_hash(my_utility.plugin_label .. "blessed_shield_elites_only")),
    cast_delay          = slider_float:new(0.01, 1.0, 0.1, get_hash(my_utility.plugin_label .. "blessed_shield_cast_delay")),
    is_independent      = checkbox:new(false, get_hash(my_utility.plugin_label .. "blessed_shield_is_independent")),
}

local function menu()
    if menu_elements.tree_tab:push("Blessed Shield") then
        menu_elements.main_boolean:render("Enable Blessed Shield", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
            menu_elements.is_independent:render("Independent Cast", "Cast independently of the rotation priority")
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
        spell_data.blessed_shield.spell_id);

    if not is_logic_allowed then return false end;

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        return false
    end

    -- Ricochet Logic: Prioritize targets with neighbors
    -- If the current target has no neighbors, try to find a better one in range
    local best_target = target
    local current_neighbors = my_utility.enemy_count_in_range(4.0, target:get_position())
    
    if current_neighbors < 2 then
        local better_target = my_target_selector.get_best_weighted_target(max_spell_range)
        if better_target then
             local better_neighbors = my_utility.enemy_count_in_range(4.0, better_target:get_position())
             if better_neighbors > current_neighbors then
                 best_target = better_target
             end
        end
    end

    if cast_spell.target(best_target, spell_data.blessed_shield.spell_id, 0, false) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + menu_elements.cast_delay:get();
        console.print("Cast Blessed Shield - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
        return true;
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
