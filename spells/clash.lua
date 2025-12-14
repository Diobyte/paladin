local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

-- Clash - Basic Skill (Melee Shield Bash)
-- Bash enemies with your shield, dealing 65% damage and generating Faith.
-- Requires a shield to be equipped.

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_clash_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.15, get_hash("paladin_rotation_clash_min_cd")),
    use_as_filler_only = checkbox:new(false, get_hash("paladin_rotation_clash_filler_only")),
    resource_threshold = slider_int:new(0, 100, 80, get_hash("paladin_rotation_clash_resource_threshold")),
}

-- Clash spell ID (estimated based on Paladin skill patterns)
-- Basic skills typically have IDs in the 2100000-2200000 range
local spell_id = 2097465  -- Clash spell ID

local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Clash") then
        menu_elements.main_boolean:render("Enable", "Enable Clash (Shield Bash)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "Minimum time between casts", 2)
            menu_elements.use_as_filler_only:render("Filler Only", "Only use when low on Faith")
            if menu_elements.use_as_filler_only:get() then
                menu_elements.resource_threshold:render("Resource Threshold %", "Use when Faith below this %")
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

    if not target or not target:is_enemy() then
        return false, 0
    end

    -- Resource generation logic:
    -- If "filler only" is OFF: Always use when Faith is below threshold (generate resource)
    -- If "filler only" is ON: Only use when very low on Faith
    local player = get_local_player()
    if player then
        local current_resource = player:get_primary_resource_current()
        local max_resource = player:get_primary_resource_max()
        if max_resource > 0 then
            local resource_pct = (current_resource / max_resource) * 100
            local threshold = menu_elements.resource_threshold:get()
            
            if menu_elements.use_as_filler_only:get() then
                -- Filler mode: only use when BELOW threshold
                if resource_pct >= threshold then
                    return false, 0
                end
            else
                -- Generator mode: use when below threshold to build up Faith
                -- Once at/above threshold, let blessed_hammer spend it
                if resource_pct >= threshold then
                    return false, 0
                end
            end
        end
    end

    -- Clash is a melee skill, check range
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
    
    -- Clash is a melee targeted attack
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
