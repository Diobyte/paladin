local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_blessed_hammer_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.01, get_hash("paladin_rotation_blessed_hammer_min_cd")),
    engage_range = slider_float:new(2.0, 25.0, 12.0, get_hash("paladin_rotation_blessed_hammer_engage_range")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_blessed_hammer_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_blessed_hammer_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_blessed_hammer_min_weight")),
}

local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Blessed Hammer") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            if menu_elements.engage_range then
                menu_elements.engage_range:render("Engage Range", "", 1)
            end
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(best_target, area_analysis)
    if not menu_elements.main_boolean:get() then return false end

    local now = my_utility.safe_get_time()
    if now < next_time_allowed_cast then return false end

    local spell_id = spell_data.blessed_hammer.spell_id
    if not my_utility.is_spell_ready(spell_id) or not my_utility.is_spell_affordable(spell_id) then
        return false
    end

    -- AoE Logic Check
    if area_analysis then
        local enemy_type_filter = menu_elements.enemy_type_filter:get()
        -- 0: All, 1: Elite+, 2: Boss
        if enemy_type_filter == 2 and area_analysis.num_bosses == 0 then return false end
        if enemy_type_filter == 1 and (area_analysis.num_elites == 0 and area_analysis.num_champions == 0 and area_analysis.num_bosses == 0) then return false end
        
        if menu_elements.use_minimum_weight:get() then
            if area_analysis.total_target_count < menu_elements.minimum_weight:get() then
                return false
            end
        end
    end

    local player = get_local_player and get_local_player() or nil
    local player_pos = player and player.get_position and player:get_position() or nil
    if player_pos then
        local engage = (menu_elements.engage_range and menu_elements.engage_range:get()) or 12.0
        local engage_sqr = engage * engage
        local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
        local near = 0

        for _, e in ipairs(enemies) do
            local is_enemy = false
            if e then
                local ok, res = pcall(function() return e:is_enemy() end)
                is_enemy = ok and res or false
            end

            if is_enemy then
                local pos = e.get_position and e:get_position() or nil
                if pos and pos:squared_dist_to_ignore_z(player_pos) <= engage_sqr then
                    near = near + 1
                    break
                end
            end
        end

        if near <= 0 then
            return false
        end
    end

    if cast_spell and type(cast_spell.self) == "function" then
        if cast_spell.self(spell_id, 0.0) then
            next_time_allowed_cast = now + menu_elements.min_cooldown:get()
            return true
        end
    end

    local target = best_target
    if not target or not target:is_enemy() then
        return false
    end

    if cast_spell and type(cast_spell.target) == "function" then
        if cast_spell.target(target, spell_id, 0.0, false) then
            next_time_allowed_cast = now + menu_elements.min_cooldown:get()
            return true
        end
    end

    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
