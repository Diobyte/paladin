-- Spear of the Heavens - Justice Skill (Judicator)
-- Cooldown: 14s | Lucky Hit: 33%
-- Rain down 4 heavenly spears from the sky, dealing 160% damage and Knocking Down enemies for 1.5s.
-- After 1.5s, the spears burst for 120% damage.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_spear_of_the_heavens_enabled")),
    min_cooldown = slider_float:new(0.0, 10.0, 0.15, get_hash("paladin_rotation_spear_of_the_heavens_min_cd")),  -- Fast burst
    cast_range = slider_float:new(5.0, 25.0, 15.0, get_hash("paladin_rotation_spear_of_the_heavens_cast_range")),  -- Max range to cast
    targeting_mode = combo_box:new(0, get_hash("paladin_rotation_spear_of_the_heavens_targeting_mode")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_spear_of_the_heavens_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_spear_of_the_heavens_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_spear_of_the_heavens_min_weight")),
    prediction_time = slider_float:new(0.1, 0.8, 0.25, get_hash("paladin_rotation_spear_of_the_heavens_prediction")),  -- Slightly faster
}

local spell_id = spell_data.spear_of_the_heavens.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Spear of the Heavens") then
        menu_elements.main_boolean:render("Enable", "Justice - 4 spears for 160% + 120% burst (CD: 14s)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.cast_range:render("Cast Range", "Maximum distance to target for casting", 1)
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, "How to select target")
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

    -- Range check - position spell has max cast range
    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    local target_pos = target:get_position()
    local cast_range = menu_elements.cast_range:get()
    
    if player_pos and target_pos then
        if not my_utility.is_in_range(target, cast_range) then
            return false, 0  -- Out of range, don't cast
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

    -- Use prediction for moving targets
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
        if cast_spell.position(spell_id, pos, 0.0) then
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
