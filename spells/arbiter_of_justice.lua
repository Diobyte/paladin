-- Arbiter of Justice - Ultimate Skill (Disciple/Mobility)
-- Cooldown: 120s | Lucky Hit: 16%
-- Ascend to the heavens and crash upon the battlefield as an Arbiter for 20 seconds, dealing 600% damage upon landing.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_arbiter_enabled")),
    min_cooldown = slider_float:new(0.2, 10.0, 0.5, get_hash("paladin_rotation_arbiter_min_cd")),  -- React fast when ult is up
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_arbiter_enemy_type")),  -- 0 = use on any target for Arbiter form
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_arbiter_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_arbiter_min_weight")),
    prediction_time = slider_float:new(0.1, 0.8, 0.25, get_hash("paladin_rotation_arbiter_prediction")),  -- Faster prediction
}

local spell_id = spell_data.arbiter_of_justice.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Arbiter of Justice") then
        menu_elements.main_boolean:render("Enable", "Ultimate - 600% landing, Arbiter form 20s (CD: 120s)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
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

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Try direct target cast first
    if cast_spell and type(cast_spell.target) == "function" then
        if cast_spell.target(target, spell_id, 0.0, false) then
            next_time_allowed_cast = now + cooldown
            return true, cooldown
        end
    end

    -- Fallback to position cast with prediction
    if cast_spell and type(cast_spell.position) == "function" then
        local pos = target:get_position()
        
        -- Use prediction for moving targets
        local prediction_time = menu_elements.prediction_time:get()
        if prediction and prediction.get_future_unit_position then
            local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
            if predicted_pos then
                pos = predicted_pos
            end
        end

        if pos and cast_spell.position(spell_id, pos, 0.0) then
            next_time_allowed_cast = now + cooldown
            return true, cooldown
        end
    end

    -- Last resort - self cast
    if cast_spell and type(cast_spell.self) == "function" then
        if cast_spell.self(spell_id, 0.0) then
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
