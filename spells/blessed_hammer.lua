-- Blessed Hammer - Core Skill (Judicator)
-- Faith Cost: 10 | Lucky Hit: 24%
-- Throw a Blessed Hammer that spirals out, dealing 115% damage.
-- Holy Damage
-- META: "Spam Blessed Hammer to deal damage" - this is THE main skill (maxroll.gg)

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_blessed_hammer_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_blessed_hammer_debug_mode")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.0, get_hash("paladin_rotation_blessed_hammer_min_cd")),  -- META: 0 = maximum spam rate
    engage_range = slider_float:new(2.0, 25.0, 15.0, get_hash("paladin_rotation_blessed_hammer_engage_range")),  -- Increased range - hammers spiral out
    min_resource = slider_int:new(0, 100, 0, get_hash("paladin_rotation_blessed_hammer_min_resource")),  -- 0 = spam freely (meta)
    min_enemies = slider_int:new(1, 15, 1, get_hash("paladin_rotation_blessed_hammer_min_enemies")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_blessed_hammer_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_blessed_hammer_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_blessed_hammer_min_weight")),
}

local spell_id = spell_data.blessed_hammer.spell_id
local next_time_allowed_cast = 0.0
local next_time_allowed_move = 0.0  -- Movement throttle (Druid pattern)
local move_delay = 0.5              -- Time between movement commands

local function menu()
    if menu_elements.tree_tab:push("Blessed Hammer") then
        menu_elements.main_boolean:render("Enable", "Core Skill - Spiraling hammer (Faith Cost: 10)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.engage_range:render("Engage Range", "Max distance to enemies for casting", 1)
            menu_elements.min_resource:render("Min Resource %", "Only cast when Faith above this % (0 = spam freely)")
            menu_elements.min_enemies:render("Min Enemies to Cast", "Minimum number of enemies nearby to cast")
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics()
    local debug_enabled = menu_elements.debug_mode:get()
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then
        if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Spell not allowed") end
        return false, 0
    end

    local player = get_local_player()
    if not player then return false, 0 end
    
    local player_pos = player:get_position()
    if not player_pos then return false, 0 end
    
    -- Resource check (Faith Cost: 10 - optional, default 0 = spam freely)
    local min_resource = menu_elements.min_resource:get()
    if min_resource > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) < min_resource then
            if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Insufficient Faith") end
            return false, 0
        end
    end
    
    local engage = menu_elements.engage_range:get()
    local min_enemies = menu_elements.min_enemies:get()
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    
    -- Count enemies in range
    local enemies = actors_manager.get_enemy_npcs()
    local near = 0
    local has_priority_target = false
    local engage_sqr = engage * engage

    for _, e in ipairs(enemies) do
        if e and e:is_enemy() then
            -- Filter out dead, immune, and untargetable enemies
            if e:is_dead() or e:is_immune() or e:is_untargetable() then
                goto continue
            end
            
            local pos = e:get_position()
            if pos and pos:squared_dist_to_ignore_z(player_pos) <= engage_sqr then
                near = near + 1
                -- Check for priority targets based on filter
                if enemy_type_filter == 2 then
                    -- Boss only
                    if e:is_boss() then has_priority_target = true end
                elseif enemy_type_filter == 1 then
                    -- Elite/Champion/Boss
                    if e:is_elite() or e:is_champion() or e:is_boss() then
                        has_priority_target = true
                    end
                else
                    has_priority_target = true  -- Any enemy counts
                end
            end
        end
        ::continue::
    end

    -- Check enemy type filter (must have at least one priority target in range)
    if enemy_type_filter > 0 and not has_priority_target then
        if debug_enabled then console.print("[BLESSED HAMMER DEBUG] No priority target found") end
        return false, 0
    end

    if near < min_enemies then
        -- DRUID PATTERN: If no enemies in engage range, move toward closest enemy
        -- This ensures we get close enough for hammers to hit
        local current_time = get_time_since_inject()
        if current_time >= next_time_allowed_move then
            -- Find closest enemy (even if outside engage range)
            local closest_enemy = nil
            local closest_dist_sqr = math.huge
            for _, e in ipairs(enemies) do
                if e and e:is_enemy() and not e:is_dead() and not e:is_immune() and not e:is_untargetable() then
                    local pos = e:get_position()
                    if pos then
                        local dist_sqr = pos:squared_dist_to_ignore_z(player_pos)
                        if dist_sqr < closest_dist_sqr then
                            closest_dist_sqr = dist_sqr
                            closest_enemy = e
                        end
                    end
                end
            end
            
            if closest_enemy then
                local target_pos = closest_enemy:get_position()
                if target_pos then
                    pathfinder.force_move_raw(target_pos)
                    next_time_allowed_move = current_time + move_delay
                    if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Moving toward closest enemy - not enough in range") end
                end
            end
        end
        return false, 0
    end

    local cooldown = menu_elements.min_cooldown:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end

    if cast_spell.self(spell_id, 0.0) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Cast successful - Enemies: " .. near) end
        return true, cooldown
    end

    if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
