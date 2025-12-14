local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_divine_lance_enabled")),
    min_cooldown = slider_float:new(0.0, 5.0, 0.5, get_hash("paladin_rotation_divine_lance_min_cd")),
}

local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Divine Lance") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(best_target, area_analysis)
    if not menu_elements.main_boolean:get() then return false end

    local now = my_utility.safe_get_time()
    if now < next_time_allowed_cast then return false end

    local spell_id = spell_data.divine_lance.spell_id
    if not my_utility.is_spell_ready(spell_id) or not my_utility.is_spell_affordable(spell_id) then
        return false
    end

    local target = best_target
    if not target or not target:is_enemy() then
        return false
    end

    local cast_pos = target:get_position()
    if not cast_pos then return false end

    -- Prediction
    if prediction and prediction.get_future_unit_position then
        local predicted_pos = prediction.get_future_unit_position(target, 0.3)
        if predicted_pos then
            cast_pos = predicted_pos
        end
    end

    if cast_spell and type(cast_spell.position) == "function" then
        if cast_spell.position(spell_id, cast_pos, 0.0) then
            next_time_allowed_cast = now + menu_elements.min_cooldown:get()
            return true
        end
    end

    if cast_spell and type(cast_spell.targeted) == "function" then
        if cast_spell.targeted(spell_id, target, 0.0) then
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
