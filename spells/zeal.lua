local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_zeal_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.01, get_hash("paladin_rotation_zeal_min_cd")),
}

local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Zeal") then
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

    local spell_id = spell_data.zeal.spell_id
    if not my_utility.is_spell_ready(spell_id) or not my_utility.is_spell_affordable(spell_id) then
        return false
    end

    local target = best_target
    if not target or not target:is_enemy() then
        return false
    end

    -- Zeal is a melee skill, so we check range
    local player = get_local_player and get_local_player() or nil
    local player_pos = player and player.get_position and player:get_position() or nil
    local target_pos = target.get_position and target:get_position() or nil
    
    if player_pos and target_pos then
        local dist_sqr = player_pos:squared_dist_to_ignore_z(target_pos)
        if dist_sqr > (3.0 * 3.0) then -- Assuming 3.0 melee range
            return false
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
