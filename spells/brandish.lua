local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_brandish_enabled")),
    min_cooldown = slider_float:new(0.0, 5.0, 0.5, get_hash("paladin_rotation_brandish_min_cd")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_brandish_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_brandish_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_brandish_min_weight")),
}

local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Brandish") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(best_target, area_analysis)
    if not menu_elements.main_boolean:get() then return false end

    local now = my_utility.safe_get_time()
    if now < next_time_allowed_cast then return false end

    local spell_id = spell_data.brandish.spell_id
    if not my_utility.is_spell_ready(spell_id) or not my_utility.is_spell_affordable(spell_id) then
        return false
    end

    -- AoE Logic Check
    if area_analysis then
        local enemy_type_filter = menu_elements.enemy_type_filter:get()
        -- 0: All, 1: Elite+, 2: Boss
        if enemy_type_filter == 2 and area_analysis.num_bosses == 0 then return false end
        if enemy_type_filter == 1 and (area_analysis.num_elites == 0 and area_analysis.num_champions == 0 and area_analysis.num_bosses == 0) then return false end
        
        if menu_elements.use_minimum_weight:get() then
            if area_analysis.total_target_count < menu_elements.minimum_weight:get() then
                return false
            end
        end
    end

    local target = best_target
    if not target or not target:is_enemy() then
        return false
    end

    if cast_spell and type(cast_spell.target) == "function" then
        if cast_spell.target(target, spell_id, 0.0, false) then
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
