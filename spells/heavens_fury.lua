-- Heaven's Fury - Ultimate Skill (Judicator)
-- Cooldown: 30s | Lucky Hit: 2.8%
-- Grasp the Light, dealing 200% damage around you per second before releasing it to seek Nearby enemies and dealing 60% damage per hit for 7 seconds.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_heavens_fury_enabled")),
    min_cooldown = slider_float:new(0.0, 40.0, 0.5, get_hash("paladin_rotation_heavens_fury_min_cd")),  -- React fast when ult is up
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_heavens_fury_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_heavens_fury_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 10.0, get_hash("paladin_rotation_heavens_fury_min_weight")),
    min_enemies = slider_int:new(1, 15, 1, get_hash("paladin_rotation_heavens_fury_min_enemies")),  -- 1 = use on any pack
}

local spell_id = spell_data.heavens_fury.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Heaven's Fury") then
        menu_elements.main_boolean:render("Enable", "Ultimate - 200%/s AoE + 60% seeking beams (CD: 30s)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.min_enemies:render("Min Enemies", "Minimum enemies nearby to cast")
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics()
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        return false, 0 
    end

    -- Heaven's Fury starts with AoE around player - check enemies nearby
    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    if not player_pos then
        return false, 0
    end
    
    -- Check for nearby enemies (initial AoE range ~6 yards)
    local engage_range = 10.0
    local engage_range_sqr = engage_range * engage_range
    local min_enemies = menu_elements.min_enemies:get()
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    
    local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
    local near = 0
    local has_priority_target = false

    for _, e in ipairs(enemies) do
        local is_enemy = false
        if e then
            local ok, res = pcall(function() return e:is_enemy() end)
            is_enemy = ok and res or false
        end
        if is_enemy then
            -- Filter out dead, immune, and untargetable targets per API guidelines
            local is_dead = false
            local is_immune = false
            local is_untargetable = false
            local ok_dead, res_dead = pcall(function() return e:is_dead() end)
            local ok_immune, res_immune = pcall(function() return e:is_immune() end)
            local ok_untarget, res_untarget = pcall(function() return e:is_untargetable() end)
            is_dead = ok_dead and res_dead or false
            is_immune = ok_immune and res_immune or false
            is_untargetable = ok_untarget and res_untarget or false
            if is_dead or is_immune or is_untargetable then
                goto continue_heavens_fury
            end

            local pos = e:get_position()
            if pos and pos:squared_dist_to_ignore_z(player_pos) <= engage_range_sqr then
                near = near + 1
                -- Check for priority targets based on filter
                if enemy_type_filter == 2 then
                    local ok, res = pcall(function() return e:is_boss() end)
                    if ok and res then has_priority_target = true end
                elseif enemy_type_filter == 1 then
                    local ok_elite, res_elite = pcall(function() return e:is_elite() end)
                    local ok_champ, res_champ = pcall(function() return e:is_champion() end)
                    local ok_boss, res_boss = pcall(function() return e:is_boss() end)
                    if (ok_elite and res_elite) or (ok_champ and res_champ) or (ok_boss and res_boss) then
                        has_priority_target = true
                    end
                else
                    has_priority_target = true
                end
            end
            ::continue_heavens_fury::
        end
    end

    -- Check enemy type filter
    if enemy_type_filter > 0 and not has_priority_target then
        return false, 0
    end

    if near < min_enemies then
        return false, 0
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Heaven's Fury is self-cast, AoE around player then seeking beams
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
