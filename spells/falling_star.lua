local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 15.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "falling_star_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "falling_star_targeting_mode")),
    min_target_range    = slider_float:new(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "falling_star_min_target_range")),
    recast_delay        = slider_float:new(0.0, 10.0, 0.5,
        get_hash(my_utility.plugin_label .. "falling_star_recast_delay")),
    min_enemy_count     = slider_int:new(1, 10, 3, get_hash(my_utility.plugin_label .. "falling_star_min_enemy_count")),
    elites_only         = checkbox:new(false, get_hash(my_utility.plugin_label .. "falling_star_elites_only")),
    cast_delay          = slider_float:new(0.01, 1.0, 0.1, get_hash(my_utility.plugin_label .. "falling_star_cast_delay")),
    is_independent      = checkbox:new(false, get_hash(my_utility.plugin_label .. "falling_star_is_independent")),
}

local function menu()
    if menu_elements.tree_tab:push("Falling Star") then
        menu_elements.main_boolean:render("Enable Falling Star", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.recast_delay:render("Recast Delay (Melee)",
                "\n     Minimum time between casts when in melee range (prevents spamming on bosses)     \n\n", 1)
            menu_elements.min_enemy_count:render("Min Enemy Count", "Minimum number of enemies in range to cast (AoE Optimization)", 1)
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
        spell_data.falling_star.spell_id);

    if not is_logic_allowed then return false end;

    if not my_utility.is_in_range(target, max_spell_range) then
        return false
    end

    -- Logic:
    -- 1. If outside min_range (Gap Close): Cast immediately.
    -- 2. If inside min_range (Boss DPS): Cast only if recast_delay has passed.
    local is_in_min_range = my_utility.is_in_range(target, menu_elements.min_target_range:get())
    
    if is_in_min_range then
        -- We are in melee range (Boss logic)
        if not target:is_boss() then return false end
        
        local current_time = get_time_since_inject()
        local last_cast = my_utility.get_last_cast_time("falling_star")
        if current_time < last_cast + menu_elements.recast_delay:get() then
            return false
        end
    end

    -- AoE Optimization: Find best cluster
    local cast_position = target:get_position()
    
    -- Use prediction for moving targets
    local predicted_position = prediction.get_future_unit_position(target, 0.5)
    if predicted_position then
        cast_position = predicted_position
    end

    local best_point_data = my_utility.get_best_point(cast_position, 5.0, {}) -- 5.0 radius estimate
    if best_point_data and best_point_data.hits >= menu_elements.min_enemy_count:get() then
        cast_position = best_point_data.point
    elseif not target:is_boss() and not target:is_elite() and best_point_data.hits < menu_elements.min_enemy_count:get() then
        -- If not enough enemies and not a priority target, skip (unless it's a gap closer)
        if is_in_min_range then
            return false
        end
    end

    if cast_spell.position(spell_data.falling_star.spell_id, cast_position, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + menu_elements.cast_delay:get();
        console.print("Cast Falling Star - Target: " ..
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
