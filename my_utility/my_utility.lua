local plugin_label = "BASE_PALADIN_PLUGIN_"

local mount_buff_name = "Generic_SetCannotBeAddedToAITargetList"
local mount_buff_name_hash_c = 1923

local shrine_conduit_buff_name = "Shine_Conduit"
local shrine_conduit_buff_name_hash_c = 421661

-- Skin name patterns for infernal horde objectives
local horde_objectives = {
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

local function safe_get_time()
    if type(get_time_since_inject) == "function" then
        return get_time_since_inject()
    end
    if type(get_current_time) == "function" then
        return get_current_time()
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

    local current_time = safe_get_time()
    if current_time < next_cast_allowed_time then
        return false
    end

    if utility and utility.is_spell_ready and not utility.is_spell_ready(spell_id) then
        return false
    end

    if utility and utility.is_spell_affordable and not utility.is_spell_affordable(spell_id) then
        return false
    end

    -- Evade abort
    local local_player = get_local_player()
    if local_player then
        local player_position = local_player:get_position()
        if evade and evade.is_dangerous_position and evade.is_dangerous_position(player_position) then
            return false
        end
    end

    if is_auto_play_enabled() then
        return true
    end

    local current_orb_mode = orbwalker and orbwalker.get_orb_mode and orbwalker.get_orb_mode()
    if current_orb_mode == orb_mode.none then
        return false
    end

    local is_current_orb_mode_pvp = current_orb_mode == orb_mode.pvp
    local is_current_orb_mode_clear = current_orb_mode == orb_mode.clear

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
    if utility and type(utility.is_spell_affordable) == "function" then
        return utility.is_spell_affordable(spell_id)
    end
    return true
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
        local pos = e:get_position()
        if pos and origin and pos:squared_dist_to_ignore_z(origin) <= radius_sqr then
            count = count + 1
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

    local dot = v1:dot_product(v2)
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
}

return my_utility
