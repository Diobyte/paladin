local M = {}

-- Simple per-object buff cache with TTL
local cache = {}
local DEFAULT_TTL = 0.2 -- seconds

-- Safe time getter with fallback (matches my_utility pattern)
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

-- Resolve a stable key for a game object
local function get_object_key(obj)
    if not obj then return nil end
    -- Prefer get_id if available
    if obj.get_id then
        local ok, id = pcall(function() return obj:get_id() end)
        if ok and id then return "id:" .. tostring(id) end
    end
    -- Fallback to tostring pointer representation
    return tostring(obj)
end

function M.get_buffs(obj, ttl)
    local key = get_object_key(obj)
    if not key then return nil end
    local now = safe_get_time()
    local entry = cache[key]
    local expire = ttl or DEFAULT_TTL
    if entry and (now - entry.t) <= expire then
        return entry.buffs
    end
    local ok, buffs = pcall(function() return obj:get_buffs() end)
    if not ok then buffs = {} end
    cache[key] = { t = now, buffs = buffs or {} }
    return buffs or {}
end

function M.clear()
    cache = {}
end

return M
