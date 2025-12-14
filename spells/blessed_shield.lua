-- Blessed Shield - Core Skill (Judicator)
-- Faith Cost: 28 | Lucky Hit: 30%
-- Bless and hurl your shield with Holy energy, dealing 216% damage that ricochets up to 3 times.
-- Holy Damage | Requires Shield
-- Note: Extended melee skill (5.5-6.0 range), works on single target or grouped enemies

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_blessed_shield_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.2, get_hash("paladin_rotation_blessed_shield_min_cd")),
    cast_range = slider_float:new(3.0, 10.0, 6.0, get_hash("paladin_rotation_blessed_shield_cast_range")),
    min_resource = slider_int:new(0, 100, 30, get_hash("paladin_rotation_blessed_shield_min_resource")),
    use_on_single_target = checkbox:new(true, get_hash("paladin_rotation_blessed_shield_single_target")),
    prefer_grouped_enemies = checkbox:new(true, get_hash("paladin_rotation_blessed_shield_prefer_grouped")),
    min_enemies_for_aoe = slider_int:new(2, 10, 2, get_hash("paladin_rotation_blessed_shield_min_enemies")),
    ricochet_grouping = slider_float:new(3.0, 10.0, 6.0, get_hash("paladin_rotation_blessed_shield_ricochet_grouping")),
}

local spell_id = spell_data.blessed_shield.spell_id

local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Blessed Shield") then
        menu_elements.main_boolean:render("Enable", "Extended melee skill (5.5-6.0 range), ricochets 3x (Faith Cost: 28)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "Minimum time between casts", 2)
            menu_elements.cast_range:render("Cast Range", "Must be within this range to cast (extended melee)", 1)
            menu_elements.min_resource:render("Min Resource %", "Only cast when Faith above this %")
            menu_elements.use_on_single_target:render("Use on Single Target", "Cast even when only one enemy is present")
            menu_elements.prefer_grouped_enemies:render("Prefer Grouped Enemies", "Prioritize casting when enemies are grouped for ricochet")
            if menu_elements.prefer_grouped_enemies:get() then
                menu_elements.min_enemies_for_aoe:render("Min Enemies for AoE", "Prefer groups of this size or larger")
                menu_elements.ricochet_grouping:render("Ricochet Grouping", "Enemies within this range count for ricochet", 1)
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

    if not target then
        return false, 0
    end
    
    local is_target_enemy = false
    local ok, res = pcall(function() return target:is_enemy() end)
    is_target_enemy = ok and res or false
    
    if not is_target_enemy then
        return false, 0
    end

    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    if not player_pos then
        return false, 0
    end
    
    -- Resource check (Faith Cost: 28 - expensive spender)
    local min_resource = menu_elements.min_resource:get()
    if min_resource > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) < min_resource then
            return false, 0
        end
    end
    
    local cast_range = menu_elements.cast_range:get()
    local cast_range_sqr = cast_range * cast_range
    
    -- Check target is in extended melee range (5.5-6.0)
    local target_pos = target:get_position()
    if not target_pos then
        return false, 0
    end
    
    local dist_sqr = player_pos:squared_dist_to_ignore_z(target_pos)
    if dist_sqr > cast_range_sqr then
        return false, 0  -- Target too far for extended melee cast
    end
    
    -- Check if we should cast based on single target / grouped enemy preferences
    local should_cast = false
    local use_single = menu_elements.use_on_single_target:get()
    local prefer_grouped = menu_elements.prefer_grouped_enemies:get()
    
    if prefer_grouped then
        -- Count enemies near target for ricochet value (shield bounces 3x)
        local ricochet_range = menu_elements.ricochet_grouping:get()
        local ricochet_range_sqr = ricochet_range * ricochet_range
        local min_enemies = menu_elements.min_enemies_for_aoe:get()
        
        local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
        local near = 0

        for _, e in ipairs(enemies) do
            if e and e:is_enemy() then
                local pos = e:get_position()
                if pos and pos:squared_dist_to_ignore_z(target_pos) <= ricochet_range_sqr then
                    near = near + 1
                end
            end
        end

        if near >= min_enemies then
            should_cast = true  -- Good ricochet opportunity
        elseif use_single and near >= 1 then
            should_cast = true  -- Single target fallback allowed
        end
    else
        -- No preference for grouped - just check single target setting
        should_cast = use_single
    end
    
    if not should_cast then
        return false, 0
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Blessed Shield is an extended melee skill
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
