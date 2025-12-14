-- Zeal - Core Skill (Zealot)
-- Faith Cost: 20 | Lucky Hit: 3%
-- Strike enemies with blinding speed, dealing 80% damage followed by 3 additional strikes dealing 20% damage each.
-- Physical Damage
-- META NOTE: With Red Sermon unique, Zeal costs LIFE instead of Faith!

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_zeal_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.05, get_hash("paladin_rotation_zeal_min_cd")),
    min_resource = slider_int:new(0, 100, 15, get_hash("paladin_rotation_zeal_min_resource")),  -- Low threshold - spam if possible
    min_enemies = slider_int:new(1, 10, 1, get_hash("paladin_rotation_zeal_min_enemies")),
    use_life_mode = checkbox:new(false, get_hash("paladin_rotation_zeal_life_mode")),
}

local spell_id = spell_data.zeal.spell_id
local next_time_allowed_cast = 0.0
local next_time_allowed_move = 0.0
local move_delay = 0.25  -- Delay between movement commands (like druid script)

local function menu()
    if menu_elements.tree_tab:push("Zeal") then
        menu_elements.main_boolean:render("Enable", "Core Skill - Fast 360 melee combo (Cost: 20 Faith or Life)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.use_life_mode:render("Red Sermon Mode", "Using Red Sermon unique (costs Life instead of Faith)")
            if not menu_elements.use_life_mode:get() then
                menu_elements.min_resource:render("Min Faith %", "Only cast when Faith above this %")
            end
            menu_elements.min_enemies:render("Min Enemies", "Minimum enemies in melee range")
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

    local player = get_local_player()
    if not player then
        return false, 0
    end
    
    -- Resource check depends on build mode
    local use_life_mode = menu_elements.use_life_mode:get()
    
    if not use_life_mode then
        -- Standard Faith cost mode
        local current_resource = player:get_primary_resource_current()
        local max_resource = player:get_primary_resource_max()
        if max_resource > 0 then
            local resource_pct = (current_resource / max_resource) * 100
            local min_resource = menu_elements.min_resource:get()
            
            -- Must have enough Faith to cast (it's a spender)
            if resource_pct < min_resource then
                return false, 0
            end
        end
    else
        -- Red Sermon mode - costs Life instead
        -- Just check we have some health (>20% to be safe)
        local health_pct = my_utility.get_health_pct()
        if health_pct and health_pct < 0.20 then
            return false, 0
        end
    end

    -- Zeal is a melee multi-strike skill, check range
    local player_pos = player:get_position()
    local target_pos = target:get_position()
    local melee_range = 3.5
    
    if player_pos and target_pos then
        local dist_sqr = player_pos:squared_dist_to_ignore_z(target_pos)
        if dist_sqr > (melee_range * melee_range) then
            -- Out of range - let main.lua handle movement
            return false, 0
        end
        
        -- Check min enemies in melee range (Zeal hits multiple times)
        local min_enemies = menu_elements.min_enemies:get()
        if min_enemies > 1 then
            local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
            local near = 0
            local melee_range_sqr = 3.5 * 3.5
            
            for _, e in ipairs(enemies) do
                local is_enemy = false
                if e then
                    local ok, res = pcall(function() return e:is_enemy() end)
                    is_enemy = ok and res or false
                end
                if is_enemy then
                    local pos = e:get_position()
                    if pos and pos:squared_dist_to_ignore_z(player_pos) <= melee_range_sqr then
                        near = near + 1
                    end
                end
            end
            
            if near < min_enemies then
                return false, 0
            end
        end
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()
    
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
