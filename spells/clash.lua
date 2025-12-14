-- Clash - Basic Skill (Juggernaut)
-- Generate Faith: 20 | Lucky Hit: 50%
-- Strike an enemy with your weapon and shield, dealing 115% damage.
-- Physical Damage | Requires Shield

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_clash_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.08, get_hash("paladin_rotation_clash_min_cd")),  -- Fast generator
    resource_threshold = slider_int:new(0, 100, 30, get_hash("paladin_rotation_clash_resource_threshold")),  -- Only gen when Faith below 30%
}

local spell_id = spell_data.clash.spell_id

local next_time_allowed_cast = 0.0
local next_time_allowed_move = 0.0
local move_delay = 0.5  -- Delay between movement commands (match druid script)

local function menu()
    if menu_elements.tree_tab:push("Clash") then
        menu_elements.main_boolean:render("Enable", "Basic Generator - 115% damage (Generate 20 Faith)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "Minimum time between casts", 2)
            menu_elements.resource_threshold:render("Resource Threshold %", "Only use when Faith BELOW this % (lower = more spender uptime)")
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
    
    -- Filter out dead, immune, and untargetable targets per API guidelines
    local is_dead = false
    local is_immune = false
    local is_untargetable = false
    local ok_dead, res_dead = pcall(function() return target:is_dead() end)
    local ok_immune, res_immune = pcall(function() return target:is_immune() end)
    local ok_untarget, res_untarget = pcall(function() return target:is_untargetable() end)
    is_dead = ok_dead and res_dead or false
    is_immune = ok_immune and res_immune or false
    is_untargetable = ok_untarget and res_untarget or false
    
    if is_dead or is_immune or is_untargetable then
        return false, 0
    end

    -- GENERATOR LOGIC: Only cast when Faith is LOW
    -- This ensures we prioritize spending Faith on damage skills
    local player = get_local_player()
    if player then
        local current_resource = player:get_primary_resource_current()
        local max_resource = player:get_primary_resource_max()
        if max_resource > 0 then
            local resource_pct = (current_resource / max_resource) * 100
            local threshold = menu_elements.resource_threshold:get()
            
            -- Only generate Faith when BELOW threshold
            if resource_pct >= threshold then
                return false, 0  -- Faith is high enough, let spenders handle it
            end
        end
    end

    -- Clash is a melee skill, check range
    local player_pos = player and player:get_position() or nil
    local target_pos = target:get_position()
    local melee_range = 3.5
    
    if player_pos and target_pos then
        local dist_sqr = player_pos:squared_dist_to_ignore_z(target_pos)
        if dist_sqr > (melee_range * melee_range) then
            -- Out of range - move toward target with throttling (Druid pattern)
            local current_time = my_utility.safe_get_time()
            if current_time >= next_time_allowed_move then
                if pathfinder and pathfinder.request_move then
                    pathfinder.request_move(target_pos)
                end
                next_time_allowed_move = current_time + move_delay
            end
            return false, 0
        end
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()
    
    -- Clash is a melee targeted attack
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
