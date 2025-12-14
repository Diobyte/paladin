-- Advance - Basic Skill (Zealot)
-- "Advance forward with your weapon, dealing 105% damage"
-- Generate Faith: 18
-- Physical Damage + Mobility
-- Targeting: cast_spell.position() - Lunge forward to target location

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_advance_enabled")),
    min_cooldown = slider_float:new(0.0, 2.0, 0.15, get_hash("paladin_rotation_advance_min_cd")),
    min_range = slider_float:new(2.0, 10.0, 3.0, get_hash("paladin_rotation_advance_min_range")),
    max_range = slider_float:new(5.0, 20.0, 12.0, get_hash("paladin_rotation_advance_max_range")),
    use_as_gap_closer = checkbox:new(true, get_hash("paladin_rotation_advance_gap_closer")),
    use_for_damage = checkbox:new(false, get_hash("paladin_rotation_advance_for_damage")),
}

local spell_id = spell_data.advance.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Advance") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.use_as_gap_closer:render("Use as Gap Closer", "Use to close distance to targets")
            if menu_elements.use_as_gap_closer:get() then
                menu_elements.min_range:render("Min Range", "Minimum distance to lunge", 1)
                menu_elements.max_range:render("Max Range", "Maximum distance to lunge", 1)
            end
            menu_elements.use_for_damage:render("Use for Damage", "Use in melee range for damage/Faith generation")
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
    local target_pos = target:get_position()
    
    if not player_pos or not target_pos then
        return false, 0
    end
    
    local dist = player_pos:dist_to(target_pos)

    -- Gap closer mode
    if menu_elements.use_as_gap_closer:get() then
        local min_r = menu_elements.min_range:get()
        local max_r = menu_elements.max_range:get()
        
        -- Only use if target is at appropriate range for gap closing
        if dist >= min_r and dist <= max_r then
            -- Check for wall collision (like barb charge)
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
        end
    end
    
    -- Damage mode - use in melee range
    if menu_elements.use_for_damage:get() then
        if dist <= 4.0 then -- Melee range
            local now = my_utility.safe_get_time()
            local cooldown = menu_elements.min_cooldown:get()

            if cast_spell and type(cast_spell.target) == "function" then
                if cast_spell.target(target, spell_id, 0.0, false) then
                    next_time_allowed_cast = now + cooldown
                    return true, cooldown
                end
            end
            
            if cast_spell and type(cast_spell.position) == "function" then
                if cast_spell.position(spell_id, target_pos, 0.0) then
                    next_time_allowed_cast = now + cooldown
                    return true, cooldown
                end
            end
        end
    end

    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
