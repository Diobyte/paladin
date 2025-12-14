local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

-- Blessed Shield - Core Skill (Melee Casted Shield Attack)
-- Throw your shield, dealing 110% damage. The shield bounces between 
-- 3 enemies within 12 yards and returns to you.
-- Requires a shield to be equipped.
-- MUST BE IN MELEE RANGE TO CAST.

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_blessed_shield_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.2, get_hash("paladin_rotation_blessed_shield_min_cd")),
    melee_range = slider_float:new(2.0, 6.0, 3.5, get_hash("paladin_rotation_blessed_shield_melee_range")),
    min_enemies = slider_int:new(1, 10, 1, get_hash("paladin_rotation_blessed_shield_min_enemies")),
}

-- Blessed Shield spell ID (estimated based on Paladin skill patterns)
local spell_id = 2082021  -- Blessed Shield spell ID

local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Blessed Shield") then
        menu_elements.main_boolean:render("Enable", "Enable Blessed Shield (Melee Casted)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "Minimum time between casts", 2)
            menu_elements.melee_range:render("Melee Range", "Must be within this range to cast", 1)
            menu_elements.min_enemies:render("Min Enemies", "Minimum enemies to cast")
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        return false, 0 
    end

    if not target or not target:is_enemy() then
        return false, 0
    end

    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    if not player_pos then
        return false, 0
    end
    
    local melee_range = menu_elements.melee_range:get()
    local melee_range_sqr = melee_range * melee_range
    local min_enemies = menu_elements.min_enemies:get()
    
    -- Check target is in MELEE range (this is a melee casted skill)
    local target_pos = target:get_position()
    if not target_pos then
        return false, 0
    end
    
    local dist_sqr = player_pos:squared_dist_to_ignore_z(target_pos)
    if dist_sqr > melee_range_sqr then
        return false, 0  -- Must be in melee range to cast
    end
    
    -- Count enemies in melee range for multi-target value
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

    -- Blessed Shield is a melee casted attack
    if cast_spell and type(cast_spell.target) == "function" then
        if cast_spell.target(target, spell_id, 0.0, false) then
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
