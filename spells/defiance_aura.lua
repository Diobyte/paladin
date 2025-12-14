local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_defiance_enabled")),
    recast_interval = slider_float:new(2.0, 60.0, 12.0, get_hash("paladin_rotation_defiance_recast")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_defiance_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_defiance_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_defiance_min_weight")),
}

local spell_id = spell_data.defiance_aura.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Defiance Aura") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.recast_interval:render("Recast Interval", "Time between recasts", 1)
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(area_analysis)
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        return false, 0 
    end

    -- Area analysis check (like barb's war_cry)
    if area_analysis then
        local enemy_type_filter = menu_elements.enemy_type_filter:get()
        -- 0: All, 1: Elite+, 2: Boss
        if enemy_type_filter == 2 and area_analysis.num_bosses == 0 then 
            return false, 0 
        end
        if enemy_type_filter == 1 and (area_analysis.num_elites == 0 and area_analysis.num_champions == 0 and area_analysis.num_bosses == 0) then 
            return false, 0 
        end
        
        if menu_elements.use_minimum_weight:get() then
            if area_analysis.total_target_count < menu_elements.minimum_weight:get() then
                return false, 0
            end
        end
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.recast_interval:get()

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
