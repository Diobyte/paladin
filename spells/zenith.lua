local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
    tree_tab        = tree_node:new(1),
    main_boolean    = checkbox:new(true, get_hash(my_utility.plugin_label .. "zenith_main_bool_base")),
    min_enemy_count = slider_int:new(1, 10, 1, get_hash(my_utility.plugin_label .. "zenith_min_enemy_count")),
    force_priority  = checkbox:new(true, get_hash(my_utility.plugin_label .. "zenith_force_priority")),
}

local function menu()
    if menu_elements.tree_tab:push("Zenith") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            -- Conditions
            menu_elements.min_enemy_count:render("Min Enemy Count", "Minimum number of enemies in range to cast", 1)

            -- Logic
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
        spell_data.zenith.spell_id);

    if not is_logic_allowed then return false end;

    local min_enemy_count = menu_elements.min_enemy_count:get()
    local force_priority = menu_elements.force_priority:get()

    if min_enemy_count > 1 then
        local enemies = actors_manager.get_enemy_npcs()
        local count = 0
        local range = 5.0 -- Zenith radius
        local player_pos = get_player_position()
        local is_priority = false

        if enemies then
            for _, enemy in ipairs(enemies) do
                if enemy:get_position():squared_dist_to_ignore_z(player_pos) <= range * range then
                    count = count + 1
                    if force_priority and (enemy:is_boss() or enemy:is_elite() or enemy:is_champion()) then
                        is_priority = true
                    end
                end
            end
        end

        if count < min_enemy_count and not is_priority then
            return false
        end
    end

    if cast_spell.self(spell_data.zenith.spell_id, 0) then
        local current_time = get_time_since_inject();
        local cast_delay = 0.1;
        next_time_allowed_cast = current_time + cast_delay;
        console.print("Cast Zenith");
        return true, cast_delay;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
