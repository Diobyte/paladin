local plugin_label = "BASE_PALADIN_PLUGIN_"

local mount_buff_name = "Generic_SetCannotBeAddedToAITargetList"
local mount_buff_name_hash_c = 1923

local shrine_conduit_buff_name = "Shine_Conduit"
local shrine_conduit_buff_name_hash_c = 421661

-- Skin name patterns for infernal horde objectives (like Druid script)
local horde_objectives = {
    "BSK_treasure_goblin",
    "BSK_HellSeeker",
    "MarkerLocation_BSK_Occupied",
    "S05_coredemon",
    "S05_fallen",
    "BSK_Structure_BonusAether",
    "BSK_Miniboss",
    "BSK_elias_boss",
    "BSK_cannibal_brute_boss",
    "BSK_skeleton_boss"
}

-- Targeting modes for flexible target selection (like Druid script)
-- Each spell can specify which targeting mode to use
local targeting_modes = {
    "Weighted Target",           -- 0: Use weighted targeting system (boss > elite > champion > normal)
    "Closest Target",            -- 1: Target closest enemy
    "Lowest Health Target",      -- 2: Target with lowest current HP
    "Highest Health Target",     -- 3: Target with highest current HP  
    "Cursor Target",             -- 4: Target closest to cursor
    "Best Cluster Target",       -- 5: Target in best cluster for AoE
}

-- Activation filters for offensive skills (like Druid script)
local activation_filters = {
    "Any Enemy",         -- 0
    "Elite & Boss Only", -- 1
    "Boss Only"          -- 2
}

-- Spell delays for timing (like Druid script)
local spell_delays = {
    instant_cast = 0.01,   -- instant cast abilities
    regular_cast = 0.10,   -- regular abilities with animation
    move_delay = 0.50,     -- delay between movement commands (like druid)
}

local evaluation_range_description = "\n      Range to check for enemies around the player      \n\n"

local targeting_mode_description =
    "       Weighted Target: Targets the most valuable enemy based on type and weights     \n" ..
    "       Closest Target: Targets the closest enemy to the player      \n" ..
    "       Lowest Health Target: Targets the enemy with lowest HP      \n" ..
    "       Highest Health Target: Targets the enemy with highest HP      \n" ..
    "       Cursor Target: Targets the enemy nearest to the cursor      \n" ..
    "       Best Cluster Target: Targets the best cluster for AoE      \n"

local function safe_get_time()
    if type(get_time_since_inject) == "function" then
        return get_time_since_inject()
    end
    -- Fallback: use get_gametime() which is documented in the API
    if type(get_gametime) == "function" then
        return get_gametime()
    end
    return 0
end

local function is_auto_play_enabled()
    -- Auto play fire spells without orbwalker
    local is_auto_play_active = auto_play and auto_play.is_active and auto_play.is_active()
    local auto_play_objective = auto_play and auto_play.get_objective and auto_play.get_objective()
    local is_auto_play_fighting = auto_play_objective == objective.fight
    if is_auto_play_active and is_auto_play_fighting then
        return true
    end
    return false
end

-- Check if a spell's buff is active on player (like Druid is_spell_active)
-- Uses spell_id as the buff name_hash
local function is_spell_active(spell_id)
    local local_player = get_local_player()
    if not local_player then return false end
    local local_player_buffs = local_player:get_buffs()
    if not local_player_buffs then return false end
    
    for _, buff in ipairs(local_player_buffs) do
        if buff.name_hash == spell_id then
            return true
        end
    end
    return false
end

-- Check if a specific buff is active (like Druid is_buff_active)
-- Checks both spell_id (name_hash) and buff_id (type) with optional stack count
local function is_buff_active(spell_id, buff_id, min_stack_count)
    min_stack_count = min_stack_count or 1
    
    local local_player = get_local_player()
    if not local_player then return false end
    local local_player_buffs = local_player:get_buffs()
    if not local_player_buffs then return false end
    
    for _, buff in ipairs(local_player_buffs) do
        if buff.name_hash == spell_id and buff.type == buff_id then
            -- Check stack count OR remaining time > 0.2
            if (buff.stacks and buff.stacks >= min_stack_count) or (buff.get_remaining_time and buff:get_remaining_time() > 0.2) then
                return true
            end
        end
    end
    return false
end

-- Get stack count of a buff (like Druid buff_stack_count)
local function buff_stack_count(spell_id, buff_id)
    local local_player = get_local_player()
    if not local_player then return 0 end
    local local_player_buffs = local_player:get_buffs()
    if not local_player_buffs then return 0 end
    
    for _, buff in ipairs(local_player_buffs) do
        if buff.name_hash == spell_id and buff.type == buff_id then
            return buff.stacks or 0
        end
    end
    return 0
end

local function is_action_allowed()
    -- Evade abort
    local local_player = get_local_player()
    if not local_player then
        return false
    end

    local player_position = local_player:get_position()
    if evade and evade.is_dangerous_position and evade.is_dangerous_position(player_position) then
        return false
    end

    local is_mounted = false
    local is_shrine_conduit = false
    local local_player_buffs = local_player:get_buffs()
    
    for _, buff in ipairs(local_player_buffs or {}) do
        if buff.name_hash == mount_buff_name_hash_c then
            is_mounted = true
            break
        end
        if buff.name_hash == shrine_conduit_buff_name_hash_c then
            is_shrine_conduit = true
            break
        end
    end

    -- Do not make any actions while mounted or with conduit buff
    if is_mounted or is_shrine_conduit then
        return false
    end

    return true
end

local function is_spell_allowed(spell_enable_check, next_cast_allowed_time, spell_id)
    if not spell_enable_check then
        return false
    end

    local current_time = get_time_since_inject()
    if current_time < next_cast_allowed_time then
        return false
    end

    -- Druid pattern: use utility API calls directly
    if not utility.is_spell_ready(spell_id) then
        return false
    end

    if not utility.is_spell_affordable(spell_id) then
        return false
    end

    if not utility.can_cast_spell(spell_id) then
        return false
    end

    -- Evade abort (Druid pattern)
    local local_player = get_local_player()
    if local_player then
        local player_position = local_player:get_position()
        if evade.is_dangerous_position(player_position) then
            return false
        end
    end

    if is_auto_play_enabled() then
        return true
    end

    -- Orbwalker mode check (matching Druid pattern exactly)
    local current_orb_mode = orbwalker.get_orb_mode()

    if current_orb_mode == orb_mode.none then
        return false
    end

    local is_current_orb_mode_pvp = current_orb_mode == orb_mode.pvp
    local is_current_orb_mode_clear = current_orb_mode == orb_mode.clear

    -- Must be in pvp or clear mode to cast spells
    if not is_current_orb_mode_pvp and not is_current_orb_mode_clear then
        return false
    end

    return true
end

local function is_spell_ready(spell_id)
    if utility and type(utility.is_spell_ready) == "function" then
        return utility.is_spell_ready(spell_id)
    end
    return false
end

local function is_spell_affordable(spell_id)
    -- Use the correct API: player:has_enough_resources_for_spell(spell_id)
    local player = get_local_player and get_local_player() or nil
    if not player then return true end  -- Assume affordable if no player
    local ok, result = pcall(function() return player:has_enough_resources_for_spell(spell_id) end)
    if ok then
        return result
    end
    return true  -- Assume affordable if method doesn't exist
end

local function get_resource_pct()
    local player = get_local_player and get_local_player() or nil
    if not player then return nil end
    if type(player.get_primary_resource_current) ~= "function" or type(player.get_primary_resource_max) ~= "function" then
        return nil
    end
    local cur = player:get_primary_resource_current()
    local max = player:get_primary_resource_max()
    if not cur or not max or max == 0 then return nil end
    return cur / max
end

local function get_health_pct()
    local player = get_local_player and get_local_player() or nil
    if not player then return nil end
    if type(player.get_current_health) ~= "function" or type(player.get_max_health) ~= "function" then
        return nil
    end
    local cur = player:get_current_health()
    local max = player:get_max_health()
    if not cur or not max or max == 0 then return nil end
    return cur / max
end

local function enemy_count_in_radius(radius, origin)
    local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
    local count = 0
    local radius_sqr = radius * radius

    for _, e in ipairs(enemies) do
        if e then
            -- Filter out dead and immune enemies per API guidelines
            local is_dead = false
            local is_immune = false
            local ok_dead, res_dead = pcall(function() return e:is_dead() end)
            local ok_immune, res_immune = pcall(function() return e:is_immune() end)
            is_dead = ok_dead and res_dead or false
            is_immune = ok_immune and res_immune or false
            
            if not is_dead and not is_immune then
                local pos = e:get_position()
                if pos and origin and pos:squared_dist_to_ignore_z(origin) <= radius_sqr then
                    count = count + 1
                end
            end
        end
    end

    return count
end

local function is_target_within_angle(origin, reference, target, max_angle)
    -- Compute direction vectors using coordinates (Lua 5.1 friendly)
    local v1 = vec3(reference:x() - origin:x(), reference:y() - origin:y(), reference:z() - origin:z()):normalize()
    local v2 = vec3(target:x() - origin:x(), target:y() - origin:y(), target:z() - origin:z()):normalize()

    -- Fallback for zero-length vectors
    if not v1 or not v2 then return true end

    -- Manual dot product calculation (vec3 doesn't have dot_product per API, only vec2 does)
    local dot = v1:x() * v2:x() + v1:y() * v2:y() + v1:z() * v2:z()
    -- Clamp to valid range to avoid NaNs due to precision
    if dot > 1 then dot = 1 elseif dot < -1 then dot = -1 end
    local angle = math.deg(math.acos(dot))
    return angle <= max_angle
end

-- Generate points around target for AoE optimization
local function generate_points_around_target(target_position, radius, num_points)
    local points = {}
    for i = 1, num_points do
        local angle = (i - 1) * (2 * math.pi / num_points)
        local x = target_position:x() + radius * math.cos(angle)
        local y = target_position:y() + radius * math.sin(angle)
        table.insert(points, vec3(x, y, target_position:z()))
    end
    return points
end

-- Get best point for AoE spells (maximize hits)
local function get_best_point(target_position, circle_radius, current_hit_list)
    local points = generate_points_around_target(target_position, circle_radius * 0.75, 8)
    local hit_table = {}

    local player_position = get_player_position and get_player_position() or nil
    local radius_sqr = circle_radius * circle_radius
    
    for _, point in ipairs(points) do
        -- Use actors_manager (documented API) instead of utility.get_units_inside_circle_list
        local all_enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
        local hit_list = {}
        for _, enemy in ipairs(all_enemies) do
            local enemy_pos = enemy:get_position()
            if enemy_pos and point:squared_dist_to_ignore_z(enemy_pos) <= radius_sqr then
                table.insert(hit_list, enemy)
            end
        end

        local hit_list_collision_less = {}
        for _, obj in ipairs(hit_list) do
            local is_wall_collision = target_selector and target_selector.is_wall_collision and target_selector.is_wall_collision(player_position, obj, 2.0)
            if not is_wall_collision then
                table.insert(hit_list_collision_less, obj)
            end
        end

        table.insert(hit_table, {
            point = point, 
            hits = #hit_list_collision_less, 
            victim_list = hit_list_collision_less
        })
    end

    -- Sort by the number of hits
    table.sort(hit_table, function(a, b) return a.hits > b.hits end)

    local current_hit_list_amount = current_hit_list and #current_hit_list or 0
    if hit_table[1] and hit_table[1].hits > current_hit_list_amount then
        return hit_table[1]
    end
    
    return {point = target_position, hits = current_hit_list_amount, victim_list = current_hit_list or {}}
end

-- Check for elite/boss/champion presence and return counts
local function should_pop_cds()
    local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
    local player_pos = get_player_position and get_player_position() or nil
    if not player_pos then return false, false, false end
    
    local elite_units = 0
    local champion_units = 0
    local boss_units = 0
    local check_range_sqr = 15 * 15
    
    for _, enemy in ipairs(enemies) do
        local enemy_pos = enemy:get_position()
        if enemy_pos and enemy_pos:squared_dist_to_ignore_z(player_pos) <= check_range_sqr then
            if enemy:is_boss() then
                boss_units = boss_units + 1
            elseif enemy:is_champion() then
                champion_units = champion_units + 1
            elseif enemy:is_elite() then
                elite_units = elite_units + 1
            end
        end
    end
    
    return elite_units > 0, champion_units > 0, boss_units > 0
end

-- Get melee range (like druid script)
local function get_melee_range()
    local melee_range = 3.5  -- Standard melee range for Paladin
    return melee_range
end

-- Check if target is in range (like druid script)
local function is_in_range(target, range)
    if not target then return false end
    local target_position = target:get_position()
    if not target_position then return false end
    local player_position = get_player_position and get_player_position() or nil
    if not player_position then return false end
    local target_distance_sqr = player_position:squared_dist_to_ignore_z(target_position)
    local range_sqr = (range * range)
    return target_distance_sqr < range_sqr
end

-- Get enemy count by type in radius (like Druid's enemy_count_in_range)
-- Returns: all, normal, elite, champion, boss
local function enemy_count_by_type(radius, origin)
    local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
    local radius_sqr = radius * radius
    origin = origin or (get_player_position and get_player_position())
    
    local all_count = 0
    local normal_count = 0
    local elite_count = 0
    local champion_count = 0
    local boss_count = 0
    
    for _, e in ipairs(enemies) do
        if e then
            -- Filter out dead, immune, untargetable
            local is_dead = false
            local is_immune = false
            local is_untargetable = false
            local ok_dead, res_dead = pcall(function() return e:is_dead() end)
            local ok_immune, res_immune = pcall(function() return e:is_immune() end)
            local ok_untarget, res_untarget = pcall(function() return e:is_untargetable() end)
            is_dead = ok_dead and res_dead or false
            is_immune = ok_immune and res_immune or false
            is_untargetable = ok_untarget and res_untarget or false
            
            if not is_dead and not is_immune and not is_untargetable then
                local pos = e:get_position()
                if pos and origin and pos:squared_dist_to_ignore_z(origin) <= radius_sqr then
                    all_count = all_count + 1
                    
                    -- Categorize by type
                    local is_boss = false
                    local is_elite = false
                    local is_champion = false
                    local ok_boss, res_boss = pcall(function() return e:is_boss() end)
                    local ok_elite, res_elite = pcall(function() return e:is_elite() end)
                    local ok_champ, res_champ = pcall(function() return e:is_champion() end)
                    is_boss = ok_boss and res_boss or false
                    is_elite = ok_elite and res_elite or false
                    is_champion = ok_champ and res_champ or false
                    
                    if is_boss then
                        boss_count = boss_count + 1
                    elseif is_champion then
                        champion_count = champion_count + 1
                    elseif is_elite then
                        elite_count = elite_count + 1
                    else
                        normal_count = normal_count + 1
                    end
                end
            end
        end
    end
    
    return all_count, normal_count, elite_count, champion_count, boss_count
end

-- Get target based on targeting mode
-- mode: 0=weighted, 1=closest, 2=lowest_hp, 3=highest_hp, 4=cursor, 5=cluster
local function get_target_by_mode(mode, range, weighted_target)
    local player_pos = get_player_position and get_player_position() or nil
    if not player_pos then return nil end
    
    local range_sqr = range * range
    local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
    
    -- Filter valid enemies in range
    local valid_enemies = {}
    for _, e in ipairs(enemies) do
        if e then
            local is_dead = false
            local is_immune = false
            local is_untargetable = false
            local ok_dead, res_dead = pcall(function() return e:is_dead() end)
            local ok_immune, res_immune = pcall(function() return e:is_immune() end)
            local ok_untarget, res_untarget = pcall(function() return e:is_untargetable() end)
            is_dead = ok_dead and res_dead or false
            is_immune = ok_immune and res_immune or false
            is_untargetable = ok_untarget and res_untarget or false
            
            if not is_dead and not is_immune and not is_untargetable then
                local pos = e:get_position()
                if pos and pos:squared_dist_to_ignore_z(player_pos) <= range_sqr then
                    table.insert(valid_enemies, {unit = e, pos = pos, dist_sqr = pos:squared_dist_to_ignore_z(player_pos)})
                end
            end
        end
    end
    
    if #valid_enemies == 0 then return nil end
    
    -- Mode 0: Weighted (use passed weighted_target or fallback to closest)
    if mode == 0 then
        if weighted_target then return weighted_target end
        -- Fallback to closest
        table.sort(valid_enemies, function(a, b) return a.dist_sqr < b.dist_sqr end)
        return valid_enemies[1].unit
    end
    
    -- Mode 1: Closest
    if mode == 1 then
        table.sort(valid_enemies, function(a, b) return a.dist_sqr < b.dist_sqr end)
        return valid_enemies[1].unit
    end
    
    -- Mode 2: Lowest Health
    if mode == 2 then
        local lowest = nil
        local lowest_hp = math.huge
        for _, entry in ipairs(valid_enemies) do
            local hp = entry.unit:get_current_health() or math.huge
            if hp < lowest_hp then
                lowest_hp = hp
                lowest = entry.unit
            end
        end
        return lowest
    end
    
    -- Mode 3: Highest Health
    if mode == 3 then
        local highest = nil
        local highest_hp = 0
        for _, entry in ipairs(valid_enemies) do
            local hp = entry.unit:get_current_health() or 0
            if hp > highest_hp then
                highest_hp = hp
                highest = entry.unit
            end
        end
        return highest
    end
    
    -- Mode 4: Cursor Target
    if mode == 4 then
        local cursor_pos = get_cursor_position and get_cursor_position() or nil
        if not cursor_pos then
            -- Fallback to closest
            table.sort(valid_enemies, function(a, b) return a.dist_sqr < b.dist_sqr end)
            return valid_enemies[1].unit
        end
        local closest_to_cursor = nil
        local closest_cursor_dist = math.huge
        for _, entry in ipairs(valid_enemies) do
            local cursor_dist = entry.pos:squared_dist_to_ignore_z(cursor_pos)
            if cursor_dist < closest_cursor_dist then
                closest_cursor_dist = cursor_dist
                closest_to_cursor = entry.unit
            end
        end
        return closest_to_cursor
    end
    
    -- Mode 5: Best Cluster (most nearby enemies)
    if mode == 5 then
        local cluster_radius_sqr = 6.0 * 6.0
        local best_cluster = nil
        local best_cluster_count = 0
        for _, entry in ipairs(valid_enemies) do
            local cluster_count = 0
            for _, other in ipairs(valid_enemies) do
                if entry.pos:squared_dist_to_ignore_z(other.pos) <= cluster_radius_sqr then
                    cluster_count = cluster_count + 1
                end
            end
            if cluster_count > best_cluster_count then
                best_cluster_count = cluster_count
                best_cluster = entry.unit
            end
        end
        return best_cluster or valid_enemies[1].unit
    end
    
    -- Default: closest
    table.sort(valid_enemies, function(a, b) return a.dist_sqr < b.dist_sqr end)
    return valid_enemies[1].unit
end

local my_utility = {
    plugin_label = plugin_label,
    safe_get_time = safe_get_time,
    is_auto_play_enabled = is_auto_play_enabled,
    is_action_allowed = is_action_allowed,
    is_spell_allowed = is_spell_allowed,
    is_spell_ready = is_spell_ready,
    is_spell_affordable = is_spell_affordable,
    get_resource_pct = get_resource_pct,
    get_health_pct = get_health_pct,
    enemy_count_in_radius = enemy_count_in_radius,
    is_target_within_angle = is_target_within_angle,
    generate_points_around_target = generate_points_around_target,
    get_best_point = get_best_point,
    should_pop_cds = should_pop_cds,
    horde_objectives = horde_objectives,
    -- Targeting modes (like Druid script)
    targeting_modes = targeting_modes,
    get_target_by_mode = get_target_by_mode,
    enemy_count_by_type = enemy_count_by_type,
    -- Movement utilities (like Druid script)
    get_melee_range = get_melee_range,
    is_in_range = is_in_range,
    spell_delays = spell_delays,
    -- Buff utilities (like Druid script)
    is_spell_active = is_spell_active,
    is_buff_active = is_buff_active,
    buff_stack_count = buff_stack_count,
    -- Activation filters (like Druid script)
    activation_filters = activation_filters,
    evaluation_range_description = evaluation_range_description,
    targeting_mode_description = targeting_mode_description,
}

return my_utility
