-- Falling Star - Valor Skill (Disciple/Mobility)
-- Cooldown: 12s | Lucky Hit: 24%
-- Soar into the air with angelic wings and dive onto the battlefield, dealing 80% damage on takeoff and 240% damage on landing.
-- Holy Damage
-- META CRITICAL: "Use Falling Star OR Condemn every few seconds to stay in Arbiter form"
-- ARBITER TRIGGER via Disciple Oath - essential for Hammerdin builds!

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_falling_star_enabled")),
    min_cooldown = slider_float:new(0.1, 10.0, 0.2, get_hash("paladin_rotation_falling_star_min_cd")),  -- Reduced for max Arbiter uptime
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_falling_star_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_falling_star_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_falling_star_min_weight")),
    prediction_time = slider_float:new(0.1, 1.0, 0.3, get_hash("paladin_rotation_falling_star_prediction")),  -- Reduced for faster landing
    min_range = slider_float:new(0.0, 10.0, 2.0, get_hash("paladin_rotation_falling_star_min_range")),  -- Min range to leap
}

local spell_id = spell_data.falling_star.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Falling Star") then
        menu_elements.main_boolean:render("Enable", "ARBITER TRIGGER - 320% damage + mobility (CD: 12s)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "Lower = more Arbiter uptime (CRITICAL)", 2)
            menu_elements.min_range:render("Min Range", "Minimum distance to target before leaping", 1)
            menu_elements.prediction_time:render("Prediction Time", "How far ahead to predict enemy position", 2)
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end
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

    -- Check minimum range (don't leap if already on top of target)
    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    local target_pos = target:get_position()
    
    if player_pos and target_pos then
        local min_range = menu_elements.min_range:get()
        local dist = player_pos:dist_to(target_pos)
        if dist < min_range then
            return false, 0  -- Too close to leap
        end
    end

    -- Enemy type filter check
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    if enemy_type_filter == 2 then
        -- Boss only
        local is_boss = false
        local ok_boss, res_boss = pcall(function() return target:is_boss() end)
        is_boss = ok_boss and res_boss or false
        if not is_boss then
            return false, 0
        end
    elseif enemy_type_filter == 1 then
        -- Elite/Champion/Boss
        local is_priority = false
        local ok_elite, res_elite = pcall(function() return target:is_elite() end)
        local ok_champ, res_champ = pcall(function() return target:is_champion() end)
        local ok_boss, res_boss = pcall(function() return target:is_boss() end)
        is_priority = (ok_elite and res_elite) or (ok_champ and res_champ) or (ok_boss and res_boss)
        if not is_priority then
            return false, 0
        end
    end

    local pos = target:get_position()
    if not pos then 
        return false, 0 
    end
    
    -- Use prediction for AoE placement
    local prediction_time = menu_elements.prediction_time:get()
    if prediction and prediction.get_future_unit_position then
        local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
        if predicted_pos then
            pos = predicted_pos
        end
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    if cast_spell and type(cast_spell.position) == "function" then
        if cast_spell.position(spell_id, pos, 0.05) then
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
