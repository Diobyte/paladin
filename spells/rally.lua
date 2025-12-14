local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_rally_enabled")),
    recast_interval = slider_float:new(0.5, 30.0, 4.0, get_hash("paladin_rotation_rally_min_cd")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_rally_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_rally_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_rally_min_weight")),
    use_resource_threshold = checkbox:new(false, get_hash("paladin_rotation_rally_use_resource")),
    resource_threshold = slider_int:new(0, 100, 40, get_hash("paladin_rotation_rally_resource_threshold")),
}

local spell_id = spell_data.rally.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Rally") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.recast_interval:render("Recast Interval", "Time between recasts", 2)
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end
            menu_elements.use_resource_threshold:render("Use Resource Threshold", "Only cast when resource below threshold")
            if menu_elements.use_resource_threshold:get() then
                menu_elements.resource_threshold:render("Resource Threshold (%)", "Cast when resource below this %")
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics()
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        return false, 0 
    end

    -- Resource threshold check (like barb's rallying cry)
    if menu_elements.use_resource_threshold:get() then
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
