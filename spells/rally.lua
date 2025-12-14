-- Rally - Valor Skill (Zealot)
-- Charges: 3 | Cooldown: 16s
-- Rally forth, gaining 20% Movement Speed for 8 seconds and generate 22 Faith.

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_rally_enabled")),
    recast_interval = slider_float:new(0.5, 30.0, 2.0, get_hash("paladin_rotation_rally_min_cd")),  -- META: Use often! Reduced from 4.0
    resource_threshold = slider_int:new(0, 100, 80, get_hash("paladin_rotation_rally_resource_threshold")),  -- Higher threshold = use more often as gen
    use_for_movespeed = checkbox:new(true, get_hash("paladin_rotation_rally_use_movespeed")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_rally_enemy_type")),
}

local spell_id = spell_data.rally.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Rally") then
        menu_elements.main_boolean:render("Enable", "Generate 22 Faith + 20% Move Speed for 8s (3 charges)")
        if menu_elements.main_boolean:get() then
            menu_elements.recast_interval:render("Recast Interval", "Time between uses", 2)
            menu_elements.use_for_movespeed:render("Use for Move Speed", "Always use Rally for move speed buff (meta recommends)")
            menu_elements.resource_threshold:render("Resource Threshold %", "Only use when Faith BELOW this % (ignored if Move Speed mode enabled)")
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
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

    local player = get_local_player()
    if not player then
        return false, 0
    end
    
    local player_pos = player:get_position()
    if not player_pos then
        return false, 0
    end
    
    -- Check for enemies nearby (no need to rally with no targets)
    local nearby = my_utility.enemy_count_in_radius(25.0, player_pos)
    if nearby == 0 then
        return false, 0
    end

    -- META BUILD: Rally should be used "as often as possible" for move speed
    -- If move speed mode is enabled, always cast when available (still need enemies though)
    local use_for_movespeed = menu_elements.use_for_movespeed:get()
    
    if not use_for_movespeed then
        -- GENERATOR LOGIC: Only cast when Faith is LOW
        local threshold = menu_elements.resource_threshold:get()
        if threshold > 0 then
            local current_resource = player:get_primary_resource_current()
            local max_resource = player:get_primary_resource_max()
            if max_resource > 0 then
                local resource_pct = (current_resource / max_resource) * 100
                
                if resource_pct >= threshold then
                    return false, 0  -- Faith is high enough, skip
                end
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
