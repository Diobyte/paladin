local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_zeal_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.01, get_hash("paladin_rotation_zeal_min_cd")),
    use_as_filler_only = checkbox:new(true, get_hash("paladin_rotation_zeal_filler_only")),
    resource_threshold = slider_int:new(0, 100, 50, get_hash("paladin_rotation_zeal_resource_threshold")),
}

local spell_id = spell_data.zeal.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Zeal") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.use_as_filler_only:render("Filler Only", "Only use when low on resource")
            if menu_elements.use_as_filler_only:get() then
                menu_elements.resource_threshold:render("Resource Threshold (%)", "Use Zeal when resource below this percentage")
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(best_target, area_analysis)
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        return false, 0 
    end

    local target = best_target
    if not target or not target:is_enemy() then
        return false, 0
    end

    -- Check filler condition (like barb's frenzy)
    if menu_elements.use_as_filler_only:get() then
        local player = get_local_player()
        if player then
            local current_resource = player:get_primary_resource_current()
            local max_resource = player:get_primary_resource_max()
            local resource_pct = (current_resource / max_resource) * 100
            local threshold = menu_elements.resource_threshold:get()
            
            if resource_pct >= threshold then
                return false, 0
            end
        end
    end

    -- Zeal is a melee skill, so we check range
    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    local target_pos = target:get_position()
    
    if player_pos and target_pos then
        local dist_sqr = player_pos:squared_dist_to_ignore_z(target_pos)
        if dist_sqr > (3.5 * 3.5) then -- 3.5 melee range
            return false, 0
        end
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()
    
    if cast_spell and type(cast_spell.target) == "function" then
        if cast_spell.target(target, spell_id, 0.0, false) then
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
