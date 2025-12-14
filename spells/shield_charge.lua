-- Shield Charge - Valor Skill (Juggernaut/Channeled/Mobility)
-- Cooldown: 10s | Lucky Hit: 35%
-- Charge with your shield and push enemies Back, granting 10% Damage Reduction and dealing 90% damage while Channeling.
-- Physical Damage | Requires Shield

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_shield_charge_enabled")),
    min_cooldown = slider_float:new(0.0, 5.0, 0.3, get_hash("paladin_rotation_shield_charge_min_cd")),  -- Fast mobility
    min_range = slider_float:new(2.0, 15.0, 6.0, get_hash("paladin_rotation_shield_charge_min_range")),  -- Only charge from mid-range
    max_range = slider_float:new(5.0, 30.0, 15.0, get_hash("paladin_rotation_shield_charge_max_range")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_shield_charge_enemy_type")),
    use_for_engage_only = checkbox:new(true, get_hash("paladin_rotation_shield_charge_engage_only")),
}

local spell_id = spell_data.shield_charge.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Shield Charge") then
        menu_elements.main_boolean:render("Enable", "Valor Channeled - 10% DR + 90% damage (CD: 10s)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.min_range:render("Min Range", "Minimum distance to target before charging", 1)
            menu_elements.max_range:render("Max Range", "Maximum distance to target for charging", 1)
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_for_engage_only:render("Use for Engage Only", "Only use Shield Charge to engage targets at range")
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

    -- Enemy type filter check (like barb's charge)
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    -- 0: All, 1: Elite+, 2: Boss
    if enemy_type_filter == 2 then
        -- Boss only - check if target is boss (with pcall protection)
        local ok_boss, is_boss = pcall(function() return target:is_boss() end)
        if not (ok_boss and is_boss) then
            return false, 0
        end
    elseif enemy_type_filter == 1 then
        -- Elite+ - check if target is elite, champion, or boss (with pcall protection)
        local ok_elite, is_elite = pcall(function() return target:is_elite() end)
        local ok_champ, is_champ = pcall(function() return target:is_champion() end)
        local ok_boss, is_boss = pcall(function() return target:is_boss() end)
        local is_priority = (ok_elite and is_elite) or (ok_champ and is_champ) or (ok_boss and is_boss)
        if not is_priority then
            return false, 0
        end
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
    
    -- Range check - must be between min and max range
    if dist < min_r or dist > max_r then
        return false, 0
    end

    -- Check for wall collision (like barb)
    if target_selector and target_selector.is_wall_collision then
        local is_wall_collision = target_selector.is_wall_collision(player_pos, target, 1.20)
        if is_wall_collision then
            return false, 0
        end
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Use prediction for moving targets
    local cast_pos = target_pos
    if prediction and prediction.get_future_unit_position then
        local predicted_pos = prediction.get_future_unit_position(target, 0.2)
        if predicted_pos then
            cast_pos = predicted_pos
        end
    end

    if cast_spell and type(cast_spell.position) == "function" then
        if cast_spell.position(spell_id, cast_pos, 0.0) then
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
