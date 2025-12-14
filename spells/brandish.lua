-- Brandish - Basic Skill (Disciple)
-- Generate Faith: 14 | Lucky Hit: 20%
-- Brandish the Light, unleashing an arc that deals 75% damage.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_brandish_enabled")),
    min_cooldown = slider_float:new(0.0, 5.0, 0.08, get_hash("paladin_rotation_brandish_min_cd")),  -- Fast backup generator
    resource_threshold = slider_int:new(0, 100, 25, get_hash("paladin_rotation_brandish_resource_threshold")),  -- Only when Faith very low (backup)
}

local spell_id = spell_data.brandish.spell_id
local next_time_allowed_cast = 0.0
local next_time_allowed_move = 0.0
local move_delay = 0.25  -- Delay between movement commands (like druid script)

local function menu()
    if menu_elements.tree_tab:push("Brandish") then
        menu_elements.main_boolean:render("Enable", "Basic Generator - Arc for 75% (Generate 14 Faith)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.resource_threshold:render("Resource Threshold %", "Only use when Faith BELOW this % (backup generator)")
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

    -- GENERATOR LOGIC: Only cast when Faith is LOW (backup generator)
    local threshold = menu_elements.resource_threshold:get()
    if threshold > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) >= threshold then
            return false, 0  -- Faith is high enough, let spenders handle it
        end
    end

    -- Range check for melee and move if needed
    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    local target_pos = target:get_position()
    local melee_range = 4.0  -- Brandish has slightly longer arc range
    
    if player_pos and target_pos then
        local dist_sqr = player_pos:squared_dist_to_ignore_z(target_pos)
        if dist_sqr > (melee_range * melee_range) then
            -- Out of range - move toward target (like druid script)
            local current_time = my_utility.safe_get_time()
            if current_time >= next_time_allowed_move then
                if pathfinder and pathfinder.force_move_raw then
                    pathfinder.force_move_raw(target_pos)
                    next_time_allowed_move = current_time + move_delay
                end
            end
            return false, 0
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
