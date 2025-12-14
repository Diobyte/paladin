local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_shield_charge_enabled")),
    min_cooldown = slider_float:new(0.0, 5.0, 0.5, get_hash("paladin_rotation_shield_charge_min_cd")),
    min_range = slider_float:new(2.0, 15.0, 5.0, get_hash("paladin_rotation_shield_charge_min_range")),
    max_range = slider_float:new(5.0, 30.0, 15.0, get_hash("paladin_rotation_shield_charge_max_range")),
}

local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Shield Charge") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.min_range:render("Min Range", "", 1)
            menu_elements.max_range:render("Max Range", "", 1)
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(best_target, area_analysis)
    if not menu_elements.main_boolean:get() then return false end

    local now = my_utility.safe_get_time()
    if now < next_time_allowed_cast then return false end

    local spell_id = spell_data.shield_charge.spell_id
    if not my_utility.is_spell_ready(spell_id) or not my_utility.is_spell_affordable(spell_id) then
        return false
    end

    local target = best_target
    if not target or not target:is_enemy() then
        return false
    end

    local player = get_local_player and get_local_player() or nil
    local player_pos = player and player.get_position and player:get_position() or nil
    local target_pos = target.get_position and target:get_position() or nil
    
    if player_pos and target_pos then
        local dist_sqr = player_pos:squared_dist_to_ignore_z(target_pos)
        local min_r = menu_elements.min_range:get()
        local max_r = menu_elements.max_range:get()
        
        if dist_sqr < (min_r * min_r) or dist_sqr > (max_r * max_r) then
            return false
        end
    end

    if cast_spell and type(cast_spell.position) == "function" then
        local cast_pos = target_pos
        
        -- Prediction
        if prediction and prediction.get_future_unit_position then
            local predicted_pos = prediction.get_future_unit_position(target, 0.2)
            if predicted_pos then
                cast_pos = predicted_pos
            end
        end

        if cast_pos and cast_spell.position(spell_id, cast_pos, 0.0) then
            next_time_allowed_cast = now + menu_elements.min_cooldown:get()
            return true
        end
    end

    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
