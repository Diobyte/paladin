-- Advance - Basic Skill (Zealot/Mobility)
-- Generate Faith: 18 | Lucky Hit: 14%
-- Advance forward with your weapon, dealing 105% damage.
-- Physical Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_advance_enabled")),
    targeting_mode = combo_box:new(4, get_hash("paladin_rotation_advance_targeting_mode")),  -- Default: 4 = Closest Target
    min_cooldown = slider_float:new(0.0, 2.0, 0.12, get_hash("paladin_rotation_advance_min_cd")),  -- Fast mobility
    min_range = slider_float:new(2.0, 10.0, 5.0, get_hash("paladin_rotation_advance_min_range")),  -- Slightly increased for gap close
    max_range = slider_float:new(5.0, 20.0, 12.0, get_hash("paladin_rotation_advance_max_range")),
    resource_threshold = slider_int:new(0, 100, 40, get_hash("paladin_rotation_advance_resource_threshold")),  -- Higher threshold = gap close more
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_advance_debug_mode")),
}

local spell_id = spell_data.advance.spell_id
local next_time_allowed_cast = 0.0
local next_time_allowed_move = 0.0
local move_delay = 0.5  -- Delay between movement commands (match druid script)

local function menu()
    if menu_elements.tree_tab:push("Advance") then
        menu_elements.main_boolean:render("Enable", "Basic Mobility - Lunge for 105% (Generate 18 Faith)")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, my_utility.targeting_mode_description)
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.min_range:render("Min Range", "Minimum distance to lunge", 1)
            menu_elements.max_range:render("Max Range", "Maximum distance to lunge", 1)
            menu_elements.resource_threshold:render("Resource Threshold %", "Only use when Faith BELOW this % (0 = always gap close)")
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    local debug_enabled = menu_elements.debug_mode:get()
    
    if not target then 
        if debug_enabled then console.print("[ADVANCE DEBUG] No target") end
        return false, 0 
    end
    
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        if debug_enabled then console.print("[ADVANCE DEBUG] Spell not allowed") end
        return false, 0
    end
    
    if not target:is_enemy() then 
        if debug_enabled then console.print("[ADVANCE DEBUG] Target not enemy") end
        return false, 0 
    end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then 
        if debug_enabled then console.print("[ADVANCE DEBUG] Target dead/immune/untargetable") end
        return false, 0 
    end

    local player = get_local_player()
    if not player then return false, 0 end
    
    local player_pos = player:get_position()
    local target_pos = target:get_position()
    
    if not player_pos or not target_pos then return false, 0 end
    
    local dist = player_pos:dist_to(target_pos)
    local min_r = menu_elements.min_range:get()
    local max_r = menu_elements.max_range:get()
    
    -- Only use if target is at appropriate range for gap closing
    if dist > max_r then 
        if debug_enabled then console.print("[ADVANCE DEBUG] Target too far: " .. string.format("%.1f", dist) .. " > " .. max_r) end
        return false, 0 
    end
    if dist < min_r then 
        if debug_enabled then console.print("[ADVANCE DEBUG] Target too close: " .. string.format("%.1f", dist) .. " < " .. min_r) end
        return false, 0 
    end
    
    -- GENERATOR LOGIC: Only use for Faith generation when Faith is LOW
    -- If threshold is 0, always allow (pure gap closer mode)
    local threshold = menu_elements.resource_threshold:get()
    if threshold > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) >= threshold then
            if debug_enabled then console.print("[ADVANCE DEBUG] Faith too high: " .. string.format("%.0f%%", resource_pct * 100) .. " >= " .. threshold .. "%") end
            return false, 0  -- Faith is high enough, save Advance for emergencies
        end
    end
    
    -- Check for wall collision
    local is_wall_collision = target_selector.is_wall_collision(player_pos, target, 1.20)
    if is_wall_collision then 
        if debug_enabled then console.print("[ADVANCE DEBUG] Wall collision detected") end
        return false, 0 
    end

    -- Advance lunges to target position (position-type spell per spell_data.lua)
    if cast_spell.position(spell_id, target_pos, 0.0) then
        local current_time = get_time_since_inject()
        local cooldown = menu_elements.min_cooldown:get()
        if cooldown < my_utility.spell_delays.regular_cast then
            cooldown = my_utility.spell_delays.regular_cast
        end
        next_time_allowed_cast = current_time + cooldown
        local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
        console.print("Cast Advance - Mode: " .. mode_name)
        return true, cooldown
    end

    if debug_enabled then console.print("[ADVANCE DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
