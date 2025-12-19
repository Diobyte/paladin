local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "consecration_main_bool_base")),
    min_enemy_count     = slider_int:new(1, 10, 3, get_hash(my_utility.plugin_label .. "consecration_min_enemy_count")),
    hp_threshold        = slider_float:new(0.0, 1.0, 0.6, get_hash(my_utility.plugin_label .. "consecration_hp_threshold")),
    cast_on_cooldown    = checkbox:new(false, get_hash(my_utility.plugin_label .. "consecration_cast_on_cooldown")),
    cast_delay          = slider_float:new(0.01, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "consecration_cast_delay")),
    is_independent      = checkbox:new(false, get_hash(my_utility.plugin_label .. "consecration_is_independent")),
}

local function menu()
    if menu_elements.tree_tab:push("Consecration") then
        menu_elements.main_boolean:render("Enable Consecration", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_enemy_count:render("Min Enemy Count", "Minimum number of enemies in range to cast", 1)
            menu_elements.hp_threshold:render("HP Threshold", "Cast when HP is below this percent (0.0 - 1.0) for healing", 2)
            menu_elements.cast_on_cooldown:render("Cast on Cooldown", "Always cast when ready (maintains buff constantly)")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
            menu_elements.is_independent:render("Independent Cast", "Cast independently of the rotation priority")
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
        spell_data.consecration.spell_id);

    if not is_logic_allowed then return false end;

    -- Check cast on cooldown option
    if menu_elements.cast_on_cooldown:get() then
        -- Cast immediately when ready with minimal delay to maintain buff
        if cast_spell.self(spell_data.consecration.spell_id, 0) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + 0.1; -- Small delay to prevent spam
            console.print("Cast Consecration (On Cooldown)");
            return true;
        end;
        return false;
    end

    -- Check HP for defensive usage
    local local_player = get_local_player();
    if local_player then
        local current_hp_pct = local_player:get_current_health() / local_player:get_max_health();
        if current_hp_pct <= menu_elements.hp_threshold:get() then
            if cast_spell.self(spell_data.consecration.spell_id, 0) then
                local current_time = get_time_since_inject();
                next_time_allowed_cast = current_time + 0.1;
                console.print("Cast Consecration (Defensive)");
                return true;
            end
        end
    end

    -- Check enemy count
    local enemy_count = my_utility.enemy_count_simple(5.0)
    if enemy_count < menu_elements.min_enemy_count:get() then
        -- Check for boss/elite exception
        local target = my_target_selector.get_target_enemy(5.0)
        if not (target and (target:is_boss() or target:is_elite())) then
            return false
        end
    end

    if cast_spell.self(spell_data.consecration.spell_id, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + menu_elements.cast_delay:get();
        console.print("Cast Consecration");
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
