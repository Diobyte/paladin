-- Zenith - Ultimate Skill (Zealot)
-- "Summon a divine sword that cleaves the battlefield for 450% damage. 
--  Casting Zenith again cuts through the battlefield for 400% damage and Knocks Down enemies for 2.0 seconds"
-- Cooldown: 25 seconds
-- Physical Damage
-- Targeting: cast_spell.self() - Melee AoE cleave around player

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_zenith_enabled")),
    min_cooldown = slider_float:new(0.0, 30.0, 0.5, get_hash("paladin_rotation_zenith_min_cd")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_zenith_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_zenith_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 8.0, get_hash("paladin_rotation_zenith_min_weight")),
    min_enemies = slider_int:new(1, 15, 2, get_hash("paladin_rotation_zenith_min_enemies")),
}

local spell_id = spell_data.zenith.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Zenith") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.min_enemies:render("Min Enemies", "Minimum enemies in melee range to cast")
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
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        return false, 0 
    end

    -- Ultimate should be saved for good situations
    if area_analysis then
        local enemy_type_filter = menu_elements.enemy_type_filter:get()
        -- 0: All, 1: Elite+, 2: Boss
        if enemy_type_filter == 2 and area_analysis.num_bosses == 0 then 
            return false, 0 
        end
        if enemy_type_filter == 1 and (area_analysis.num_elites == 0 and area_analysis.num_champions == 0 and area_analysis.num_bosses == 0) then 
            return false, 0 
        end
        
        if menu_elements.use_minimum_weight:get() then
            if area_analysis.total_target_count < menu_elements.minimum_weight:get() then
                return false, 0
            end
        end
    end

    -- Zenith is a melee AoE cleave - check for enemies in melee range
    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    if not player_pos then
        return false, 0
    end
    
    -- Zenith has melee/short range cleave (~5 yard radius)
    local melee_range = 6.0
    local melee_range_sqr = melee_range * melee_range
    local min_enemies = menu_elements.min_enemies:get()
    
    local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
    local near = 0

    for _, e in ipairs(enemies) do
        if e and e:is_enemy() then
            local pos = e:get_position()
            if pos and pos:squared_dist_to_ignore_z(player_pos) <= melee_range_sqr then
                near = near + 1
            end
        end
    end

    if near < min_enemies then
        return false, 0
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Zenith is self-cast melee AoE cleave
    if cast_spell and type(cast_spell.self) == "function" then
        if cast_spell.self(spell_id, 0.0) then
            next_time_allowed_cast = now + cooldown
            return true, cooldown
        end
    end

    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
