local function safe_get_time()
    if type(get_time_since_inject) == "function" then
        return get_time_since_inject()
    end
    if type(get_current_time) == "function" then
        return get_current_time()
    end
    return 0
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

local my_utility = {
    safe_get_time = safe_get_time,
    is_spell_ready = is_spell_ready,
    is_spell_affordable = is_spell_affordable,
    get_resource_pct = get_resource_pct,
    get_health_pct = get_health_pct,
    enemy_count_in_radius = enemy_count_in_radius,
}

return my_utility
