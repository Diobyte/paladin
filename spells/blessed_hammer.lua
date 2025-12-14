-- Blessed Hammer - Core Skill (Judicator)
-- Faith Cost: 10 | Lucky Hit: 24%
-- Throw a Blessed Hammer that spirals out, dealing 115% damage.
-- Holy Damage
-- META: "Spam Blessed Hammer to deal damage" - this is THE main skill (maxroll.gg)

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_blessed_hammer_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.0, get_hash("paladin_rotation_blessed_hammer_min_cd")),  -- META: 0 = maximum spam rate
    engage_range = slider_float:new(2.0, 25.0, 15.0, get_hash("paladin_rotation_blessed_hammer_engage_range")),  -- Increased range - hammers spiral out
    min_resource = slider_int:new(0, 100, 0, get_hash("paladin_rotation_blessed_hammer_min_resource")),  -- 0 = spam freely (meta)
    min_enemies = slider_int:new(1, 15, 1, get_hash("paladin_rotation_blessed_hammer_min_enemies")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_blessed_hammer_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_blessed_hammer_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_blessed_hammer_min_weight")),
}

local spell_id = spell_data.blessed_hammer.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Blessed Hammer") then
        menu_elements.main_boolean:render("Enable", "Core Skill - Spiraling hammer (Faith Cost: 10)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.engage_range:render("Engage Range", "Max distance to enemies for casting", 1)
            menu_elements.min_resource:render("Min Resource %", "Only cast when Faith above this % (0 = spam freely)")
            menu_elements.min_enemies:render("Min Enemies to Cast", "Minimum number of enemies nearby to cast")
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

    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    if not player_pos then
        return false, 0
    end
    
    -- Resource check (Faith Cost: 10 - optional, default 0 = spam freely)
    local min_resource = menu_elements.min_resource:get()
    if min_resource > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) < min_resource then
            return false, 0
        end
    end
    
    local engage = menu_elements.engage_range:get()
    local engage_sqr = engage * engage
    local min_enemies = menu_elements.min_enemies:get()
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    
    -- Count enemies in range (like barb's HotA min targets)
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
            local pos = e:get_position()
            if pos and pos:squared_dist_to_ignore_z(player_pos) <= engage_sqr then
                near = near + 1
                -- Check for priority targets based on filter
                if enemy_type_filter == 2 then
                    -- Boss only
                    local ok, res = pcall(function() return e:is_boss() end)
                    if ok and res then has_priority_target = true end
                elseif enemy_type_filter == 1 then
                    -- Elite/Champion/Boss
                    local ok_elite, res_elite = pcall(function() return e:is_elite() end)
                    local ok_champ, res_champ = pcall(function() return e:is_champion() end)
                    local ok_boss, res_boss = pcall(function() return e:is_boss() end)
                    if (ok_elite and res_elite) or (ok_champ and res_champ) or (ok_boss and res_boss) then
                        has_priority_target = true
                    end
                else
                    has_priority_target = true  -- Any enemy counts
                end
            end
        end
    end

    -- Check enemy type filter (must have at least one priority target in range)
    if enemy_type_filter > 0 and not has_priority_target then
        return false, 0
    end

    if near < min_enemies then
        return false, 0
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Cast at self (AoE spiral around player) - this is how Blessed Hammer works
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
