local plugin_label = "BASE_PALADIN_PLUGIN_"

local mount_buff_name = "Generic_SetCannotBeAddedToAITargetList"
local mount_buff_name_hash_c = 1923

local shrine_conduit_buff_name = "Shrine_Conduit"
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

-- Targeting modes for flexible target selection (matching Druid script exactly)
-- Each spell can specify which targeting mode to use via menu combo_box
-- The main.lua evaluates ALL these target types and passes the correct one based on spell's mode
local targeting_modes = {
    "Ranged Target",              -- 0: Best weighted target for ranged spells (10+ range)
    "Ranged Target (in sight)",   -- 1: Same as 0 but with visibility/collision check
    "Melee Target",               -- 2: Best weighted target for melee spells (melee range)
    "Melee Target (in sight)",    -- 3: Same as 2 but with visibility check
    "Closest Target",             -- 4: Closest enemy by distance
    "Closest Target (in sight)",  -- 5: Closest with visibility check
    "Best Cursor Target",         -- 6: Best weighted target near cursor
    "Closest Cursor Target",      -- 7: Closest enemy to cursor position
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
    move_delay = 0.35,     -- delay between movement commands (like druid)
    cast_fail_delay = 0.15, -- delay after a failed cast before retry (prevents spam)
}

-- Safe time helper (centralized)
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

-- Safe cursor position helper
local function get_cursor_position_safe()
    if type(get_cursor_position) == "function" then
        return get_cursor_position()
    end
    return nil
end

-- Expose for other modules (avoids circular requires)
_G.my_utility_safe_get_time = safe_get_time

-- =====================================================
-- GLOBAL MOVEMENT STATE (Spiritborn/Druid Pattern)
-- Centralized movement tracking prevents oscillation from
-- multiple spells competing for movement control
-- =====================================================
local next_time_allowed_move = 0.0
local current_move_target_id = nil
local last_move_time = 0.0

-- Check if movement is currently allowed (global throttle)
local function can_move_now()
    local current_time = safe_get_time()
    return current_time >= next_time_allowed_move
end

-- Request movement to a target position (Spiritborn pattern)
-- Uses request_move which only sends command if not already moving to same destination
-- IMPORTANT: Unlike force_move_raw, request_move is designed to be called every frame
-- No throttling needed because request_move handles it internally
-- Returns true always (movement was requested or already in progress)
local function move_to_target(target_pos, optional_target_id)
    if not target_pos then
        return false
    end
    -- Respect manual play: allow user to control movement fully
    if _G.PaladinRotation and _G.PaladinRotation.manual_play then
        return false
    end

    -- Use request_move directly - it's designed to be called every frame
    -- Per API: "pathfinder.request_move only sends command if player isn't already moving"
    if pathfinder and pathfinder.request_move then
        pathfinder.request_move(target_pos)
    elseif pathfinder and pathfinder.force_move_raw then
        -- Fallback to force_move_raw with throttle if request_move not available
        local current_time = safe_get_time()
        if current_time >= next_time_allowed_move then
            pathfinder.force_move_raw(target_pos)
            next_time_allowed_move = current_time + spell_delays.move_delay
        end
    end
    
    -- Track for debugging/stuck detection
    current_move_target_id = optional_target_id
    last_move_time = safe_get_time()
    return true
end

-- Check if we're stuck (no movement progress)
local function is_stuck(threshold_time)
    threshold_time = threshold_time or 2.0
    local current_time = safe_get_time()
    return (current_time - last_move_time) > threshold_time
end

-- Clear movement state (call when combat target changes)
local function clear_move_state()
    current_move_target_id = nil
end

-- Check if movement was requested recently (to prevent overriding spell movement)
local function was_movement_requested_recently(threshold)
    threshold = threshold or 0.1
    local current_time = safe_get_time()
    return (current_time - last_move_time) < threshold
end

local evaluation_range_description = "\n      Range to check for enemies around the player      \n\n"

local targeting_mode_description =
    "       Ranged Target: Best weighted target for ranged spells      \n" ..
    "       Ranged Target (in sight): Ranged with visibility check      \n" ..
    "       Melee Target: Best weighted target for melee spells      \n" ..
    "       Melee Target (in sight): Melee with visibility check      \n" ..
    "       Closest Target: Target closest enemy by distance (fixes group targeting!)      \n" ..
    "       Closest Target (in sight): Closest with visibility check      \n" ..
    "       Best Cursor Target: Best weighted target near cursor      \n" ..
    "       Closest Cursor Target: Closest enemy to cursor position      \n"

local function is_auto_play_enabled()
    -- Safely detect if auto_play is toggled on; avoid crashing when objective enums are absent
    if not (auto_play and auto_play.is_active) then
        return false
    end

    local ok_active, is_active = pcall(auto_play.is_active)
    if not ok_active or not is_active then
        return false
    end

    -- Some environments expose a mode/objective getter; treat "fight"/"combat" as active combat
    local ok_objective, objective_value = pcall(function()
        if auto_play.get_mode then
            return auto_play.get_mode()
        end
        if auto_play.get_objective then
            return auto_play.get_objective()
        end
        return nil
    end)

    if ok_objective and objective_value then
        if type(objective_value) == "string" then
            local normalized = objective_value:lower()
            if normalized == "fight" or normalized == "combat" or normalized == "pvp" then
                return true
            end
        elseif type(objective_value) == "table" and objective_value.fight then
            return true
        end
    end

    -- Default to true when auto_play is active but objective is unavailable
    return true
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
        local name_hash = buff.name_hash
        local buff_name = ""
        if buff.get_name then
            local ok, name = pcall(function() return buff:get_name() end)
            if ok and name then buff_name = tostring(name) end
        elseif buff.name then
            buff_name = tostring(buff.name)
        end
        local normalized_name = buff_name:lower()

        if name_hash == mount_buff_name_hash_c or normalized_name:find("mount") or normalized_name:find("horse") then
            is_mounted = true
        end

        -- Conduit shrine detection (typo-safe)
        if name_hash == shrine_conduit_buff_name_hash_c or normalized_name:find("conduit") then
            is_shrine_conduit = true
        end

        if is_mounted and is_shrine_conduit then
            break
        end
    end

    -- Do not make any actions while mounted or with conduit buff
    if is_mounted or is_shrine_conduit then
        return false
    end

    return true
end

-- Check if PvP is active (based on orbwalker mode)
local function is_pvp_active()
    if orbwalker and orbwalker.get_orb_mode then
        local ok, mode = pcall(function() return orbwalker.get_orb_mode() end)
        if ok and mode == orb_mode.pvp then
            return true
        end
    end
    return false
end

local function is_spell_ready(spell_id)
    -- Prefer the documented API: player:is_spell_ready(spell_id)
    local player = get_local_player and get_local_player() or nil
    if player and type(player.is_spell_ready) == "function" then
        local ok, ready = pcall(function() return player:is_spell_ready(spell_id) end)
        if ok then
            return ready
        end
    end

    -- Fallback to utility module if present
    if utility and type(utility.is_spell_ready) == "function" then
        local ok, ready = pcall(function() return utility.is_spell_ready(spell_id) end)
        if ok then
            return ready
        end
    end

    -- Default to true so rotations can proceed even if readiness APIs are unavailable
    return true
end

local function is_spell_allowed(spell_enable_check, next_cast_allowed_time, spell_id, debug_mode)
    if not spell_enable_check then
        if debug_mode then console.print("[is_spell_allowed] spell_enable_check is false") end
        return false
    end

    local current_time = safe_get_time()
    if current_time < next_cast_allowed_time then
        if debug_mode then console.print("[is_spell_allowed] waiting for next_cast_allowed_time") end
        return false
    end

    -- Check spell cooldown with safe wrapper (avoids hard dependency on global utility)
    if not is_spell_ready(spell_id) then
        if debug_mode then console.print("[is_spell_allowed] spell not ready (cooldown)") end
        return false
    end

    -- Check resource availability (documented API: player:has_enough_resources_for_spell)
    local local_player = get_local_player()
    if local_player then
        -- Use pcall for safety in case method doesn't exist
        local ok, has_resources = pcall(function()
            return local_player:has_enough_resources_for_spell(spell_id)
        end)
        if ok and not has_resources then
            if debug_mode then console.print("[is_spell_allowed] not enough resources") end
            return false
        end
        
        -- Evade abort (check if player is in dangerous position)
        local player_position = local_player:get_position()
        if player_position and evade and evade.is_dangerous_position then
            if evade.is_dangerous_position(player_position) then
                if debug_mode then console.print("[is_spell_allowed] in dangerous position (evade)") end
                return false
            end
        end
    end

    if is_auto_play_enabled() then
        if debug_mode then console.print("[is_spell_allowed] auto_play enabled - allowed") end
        return true
    end

    -- Orbwalker mode check (matching Spiritborn pattern)
    local current_orb_mode = nil
    if orbwalker and orbwalker.get_orb_mode then
        local ok_mode, mode_val = pcall(function() return orbwalker.get_orb_mode() end)
        if ok_mode then current_orb_mode = mode_val end
    end

    -- If orbwalker is unavailable, or returns nil/none, allow casting (default to self-managed rotation)
    if current_orb_mode == nil or (orb_mode and current_orb_mode == orb_mode.none) then
        if debug_mode then console.print("[is_spell_allowed] orbwalker idle/none; allowing cast") end
        return true
    end

    -- Allow all active orbwalker modes (pvp, clear, flee) by default; do not block casting
    -- This avoids the script stalling when the orbwalker is in a non-standard mode
    if debug_mode then console.print("[is_spell_allowed] ALLOWED") end
    return true
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

local function enemy_count_in_radius(radius, origin, floor_height_threshold)
    -- Default to player position if no origin provided
    origin = origin or (get_player_position and get_player_position())
    if not origin then return 0 end
    
    -- Default floor height threshold (elevation filter) - matches Druid/Spiritborn reference repos
    floor_height_threshold = floor_height_threshold or 5.0
    
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
                if pos then
                    -- Check horizontal distance
                    if pos:squared_dist_to_ignore_z(origin) <= radius_sqr then
                        -- Check elevation/floor difference (prevents counting enemies on different floors)
                        local z_difference = math.abs(origin:z() - pos:z())
                        if z_difference <= floor_height_threshold then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end

    return count
end

local function is_target_within_angle(origin, reference, target, max_angle)
    -- Compute direction vectors using coordinates (Lua 5.1 friendly)
    local v1 = vec3.new(reference:x() - origin:x(), reference:y() - origin:y(), reference:z() - origin:z()):normalize()
    local v2 = vec3.new(target:x() - origin:x(), target:y() - origin:y(), target:z() - origin:z()):normalize()

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
        table.insert(points, vec3.new(x, y, target_position:z()))
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

-- Get target based on targeting mode (matching Druid's 8-mode system)
-- mode: 0=ranged, 1=ranged_visible, 2=melee, 3=melee_visible, 4=closest, 5=closest_visible, 6=best_cursor, 7=closest_cursor
-- This function is called from main.lua with pre-evaluated targets for efficiency
local function get_target_by_mode(mode, targets)
    -- targets is a table with pre-evaluated targets from main.lua:
    -- {best_ranged, best_ranged_visible, best_melee, best_melee_visible, closest, closest_visible, best_cursor, closest_cursor}
    if not targets then return nil end
    
    if mode == 0 then return targets.best_ranged end
    if mode == 1 then return targets.best_ranged_visible end
    if mode == 2 then return targets.best_melee end
    if mode == 3 then return targets.best_melee_visible end
    if mode == 4 then return targets.closest end
    if mode == 5 then return targets.closest_visible end
    if mode == 6 then return targets.best_cursor end
    if mode == 7 then return targets.closest_cursor end
    
    -- Default to closest for safety
    return targets.closest or targets.best_melee
end

-- Legacy function for backward compatibility - evaluates targets on-demand
-- Use get_target_by_mode with pre-evaluated targets for better performance
local function get_target_by_mode_legacy(mode, range, weighted_target)
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
    get_cursor_position = get_cursor_position_safe,
    get_cursor_pos = get_cursor_position_safe, -- Alias
    enemy_count_in_radius = enemy_count_in_radius,
    enemy_count_in_range = enemy_count_in_radius,  -- Alias for backward compatibility
    is_target_within_angle = is_target_within_angle,
    generate_points_around_target = generate_points_around_target,
    get_best_point = get_best_point,
    should_pop_cds = should_pop_cds,
    horde_objectives = horde_objectives,
    -- Targeting modes (like Spiritborn script - 8 modes)
    targeting_modes = targeting_modes,
    get_target_by_mode = get_target_by_mode,
    get_target_by_mode_legacy = get_target_by_mode_legacy,  -- For backward compatibility
    enemy_count_by_type = enemy_count_by_type,
    -- Movement utilities (like Spiritborn script)
    get_melee_range = get_melee_range,
    is_in_range = is_in_range,
    spell_delays = spell_delays,
    -- Centralized movement system
    can_move_now = can_move_now,
    move_to_target = move_to_target,
    is_stuck = is_stuck,
    clear_move_state = clear_move_state,
    was_movement_requested_recently = was_movement_requested_recently,
    is_pvp_active = is_pvp_active,
    -- Buff utilities (like Spiritborn script)
    is_spell_active = is_spell_active,
    is_buff_active = is_buff_active,
    buff_stack_count = buff_stack_count,
    -- Activation filters (like Spiritborn script)
    activation_filters = activation_filters,
    evaluation_range_description = evaluation_range_description,
    targeting_mode_description = targeting_mode_description,
}

return my_utility
