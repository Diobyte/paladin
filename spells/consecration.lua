local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(true, get_hash(my_utility.plugin_label .. "consecration_main_bool_base")),
    min_enemy_count  = slider_int:new(1, 10, 1, get_hash(my_utility.plugin_label .. "consecration_min_enemy_count")),
    hp_threshold     = slider_float:new(0.0, 1.0, 0.5, get_hash(my_utility.plugin_label .. "consecration_hp_threshold"),
        2),
    cast_on_cooldown = checkbox:new(false, get_hash(my_utility.plugin_label .. "consecration_cast_on_cooldown")),
    force_priority   = checkbox:new(true, get_hash(my_utility.plugin_label .. "consecration_force_priority")),
}

local function menu()
    if menu_elements.tree_tab:push("Consecration") then
        menu_elements.main_boolean:render("Enable Spell", "Enable or disable this spell")

        if menu_elements.main_boolean:get() then
            -- Conditions
            menu_elements.min_enemy_count:render("Min Enemy Count", "Minimum number of enemies in range to cast", 1)
            menu_elements.hp_threshold:render("HP Threshold",
                "Cast when HP is below this percent (0.0 - 1.0) for healing", 2)

            -- Logic
            menu_elements.cast_on_cooldown:render("Cast on Cooldown",
                "Always cast when ready (maintains buff constantly)")
            menu_elements.force_priority:render("Force Priority", "Always cast on Boss/Elite/Champion (if applicable)")
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
            return true, 0.1;
        end;
        return false;
    end

    local local_player = get_local_player()
    local player_pos = local_player:get_position()
    local current_hp_pct = local_player:get_current_health() / local_player:get_max_health()
    local hp_threshold = menu_elements.hp_threshold:get()

    -- 1. Heal Logic
    if current_hp_pct <= hp_threshold then
        if cast_spell.self(spell_data.consecration.spell_id, 0) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + 0.1;
            console.print("Cast Consecration (Heal)");
            return true, 0.1;
        end
    end

    -- 2. AOE / Priority Logic
    local min_enemy_count = menu_elements.min_enemy_count:get()
    local force_priority = menu_elements.force_priority:get()
    local enemies = actors_manager.get_enemy_npcs()
    local count = 0
    local range = 5.0 -- Consecration radius

    if enemies then
        for _, enemy in ipairs(enemies) do
            local dist_sq = enemy:get_position():squared_dist_to_ignore_z(player_pos)
            if dist_sq <= range * range then
                count = count + 1
                if force_priority and (enemy:is_boss() or enemy:is_elite() or enemy:is_champion()) then
                    if cast_spell.self(spell_data.consecration.spell_id, 0) then
                        local current_time = get_time_since_inject();
                        next_time_allowed_cast = current_time + 0.1;
                        console.print("Cast Consecration (Priority)");
                        return true, 0.1;
                    end
                end
            end
        end
    end

    if count >= min_enemy_count then
        if cast_spell.self(spell_data.consecration.spell_id, 0) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + 0.1;
            console.print("Cast Consecration (AOE " .. count .. ")");
            return true, 0.1;
        end;
    end

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
