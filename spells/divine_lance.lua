local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_divine_lance_enabled")),
    min_cooldown = slider_float:new(0.0, 5.0, 0.2, get_hash("paladin_rotation_divine_lance_min_cd")),
    prediction_time = slider_float:new(0.1, 0.8, 0.3, get_hash("paladin_rotation_divine_lance_prediction")),
}

local spell_id = spell_data.divine_lance.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Divine Lance") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.prediction_time:render("Prediction Time", "How far ahead to predict enemy position", 2)
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

    if not target or not target:is_enemy() then
        return false, 0
    end

    local cast_pos = target:get_position()
    if not cast_pos then 
        return false, 0 
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Divine Lance is primarily a melee/short-range impale skill
    -- "Impale enemies with a heavenly lance, stabbing 2 times for 90% damage each"
    -- Try direct target cast first (preferred for melee impale)
    if cast_spell and type(cast_spell.target) == "function" then
        if cast_spell.target(target, spell_id, 0.0, false) then
            next_time_allowed_cast = now + cooldown
            return true, cooldown
        end
    end

    -- Fallback to position cast with prediction (for Divine Javelin upgrade - ranged throw)
    local cast_pos = target:get_position()
    local prediction_time = menu_elements.prediction_time:get()
    if prediction and prediction.get_future_unit_position then
        local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
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
