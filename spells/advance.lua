-- Advance - Basic Skill (Zealot/Mobility)
-- Generate Faith: 18 | Lucky Hit: 14%
-- Advance forward with your weapon, dealing 105% damage.
-- Physical Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_advance_enabled")),
    min_cooldown = slider_float:new(0.0, 2.0, 0.15, get_hash("paladin_rotation_advance_min_cd")),
    min_range = slider_float:new(2.0, 10.0, 4.0, get_hash("paladin_rotation_advance_min_range")),
    max_range = slider_float:new(5.0, 20.0, 12.0, get_hash("paladin_rotation_advance_max_range")),
    resource_threshold = slider_int:new(0, 100, 35, get_hash("paladin_rotation_advance_resource_threshold")),
}

local spell_id = spell_data.advance.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Advance") then
        menu_elements.main_boolean:render("Enable", "Basic Mobility - Lunge for 105% (Generate 18 Faith)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.min_range:render("Min Range", "Minimum distance to lunge", 1)
            menu_elements.max_range:render("Max Range", "Maximum distance to lunge", 1)
            menu_elements.resource_threshold:render("Resource Threshold %", "Only use when Faith BELOW this % (0 = always gap close)")
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

    if not target then
        return false, 0
    end
    
    local is_target_enemy = false
    local ok, res = pcall(function() return target:is_enemy() end)
    is_target_enemy = ok and res or false
    
    if not is_target_enemy then
        return false, 0
    end

    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    local target_pos = target:get_position()
    
    if not player_pos or not target_pos then
        return false, 0
    end
    
    local dist = player_pos:dist_to(target_pos)
    local min_r = menu_elements.min_range:get()
    local max_r = menu_elements.max_range:get()
    
    -- Only use if target is at appropriate range for gap closing
    if dist < min_r or dist > max_r then
        return false, 0
    end
    
    -- GENERATOR LOGIC: Only use for Faith generation when Faith is LOW
    -- If threshold is 0, always allow (pure gap closer mode)
    local threshold = menu_elements.resource_threshold:get()
    if threshold > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) >= threshold then
            return false, 0  -- Faith is high enough, save Advance for emergencies
        end
    end
    
    -- Check for wall collision
    if target_selector and target_selector.is_wall_collision then
        local is_wall_collision = target_selector.is_wall_collision(player_pos, target, 1.20)
        if is_wall_collision then
            return false, 0
        end
    end
    
    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Advance lunges to target position
    if cast_spell and type(cast_spell.position) == "function" then
        if cast_spell.position(spell_id, target_pos, 0.0) then
            next_time_allowed_cast = now + cooldown
            return true, cooldown
        end
    end
    
    -- Fallback to target cast
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
