-- Ensure utility and my_utility stubs are available for tests
package.loaded['my_utility/my_utility'] = package.loaded['my_utility/my_utility'] or
    { is_buff_active = function() return false end }
package.loaded['utility'] = package.loaded['utility'] or { is_spell_ready = function() return true end }
package.loaded['actors_manager'] = package.loaded['actors_manager'] or { get_enemy_actors = function() return {} end }
local ok, get_spell_priority = pcall(require, 'spell_priority')
if not ok then
    print('TEST FAIL: could not require spell_priority:', get_spell_priority)
    os.exit(1)
end

local base = get_spell_priority.get_base_spell_priority(0)
local function find_index(tbl, val)
    for i, v in ipairs(tbl) do if v == val then return i end end
    return nil
end

-- Mock get_local_player for low Faith scenario
local orig_get_local_player = _G.get_local_player
local orig_utility = _G.utility
local orig_actors_manager = _G.actors_manager
local orig_my_utility = _G.my_utility

_G.utility = { is_spell_ready = function() return true end }
_G.actors_manager = { get_enemy_actors = function() return {} end }
_G.my_utility = { is_buff_active = function() return false end }

_G.get_local_player = function()
    return {
        get_primary_resource_current = function() return 5 end,
        get_primary_resource_max = function() return 100 end,
        get_current_health = function() return 100 end,
        get_max_health = function() return 100 end,
    }
end

local adjusted = get_spell_priority.apply_dynamic_adjustments(base, 0)
local base_rally_idx = find_index(base, 'rally')
local adj_rally_idx = find_index(adjusted, 'rally')
if not base_rally_idx or not adj_rally_idx then
    print('TEST FAIL: rally missing')
    os.exit(1)
end
if adj_rally_idx >= base_rally_idx then
    print('TEST FAIL: rally did not move up under low Faith (base idx', base_rally_idx, 'adj idx', adj_rally_idx, ')')
    os.exit(1)
end

print('TEST PASS: rally moved up under low Faith (', base_rally_idx, '->', adj_rally_idx, ')')

-- Mock Auradin with critical health for Aegis emergency
_G.get_local_player = function()
    return {
        get_primary_resource_current = function() return 80 end,
        get_primary_resource_max = function() return 100 end,
        get_current_health = function() return 20 end,
        get_max_health = function() return 100 end,
    }
end

_G.DEBUG_SPELL_PRIORITY_PREFILL = true
local adjusted_auradin_prefill = get_spell_priority.apply_dynamic_adjustments(
    get_spell_priority.get_base_spell_priority(12), 12)
_G.DEBUG_SPELL_PRIORITY_PREFILL = nil

-- DEBUG dump
print('Auradin prefill (first 10):')
for i = 1, 10 do print(i, tostring(adjusted_auradin_prefill[i])) end

local function find_index_in_prefill(tbl, name)
    for i = 1, #tbl do if tbl[i] == name then return i end end
    return nil
end

local aegis_prefill_idx = find_index_in_prefill(adjusted_auradin_prefill, 'aegis')
local base_aegis_idx = find_index(base, 'aegis')
if not aegis_prefill_idx or not base_aegis_idx then
    print('TEST FAIL: aegis missing')
    os.exit(1)
end

if aegis_prefill_idx >= base_aegis_idx then
    print('TEST FAIL: aegis did not move earlier under Auradin emergency (base idx', base_aegis_idx, 'prefill idx',
        aegis_prefill_idx, ')')
    os.exit(1)
end

print('TEST PASS: aegis moved earlier under Auradin emergency (', base_aegis_idx, '->', aegis_prefill_idx, ')')

-- Restore globals
_G.get_local_player = orig_get_local_player
_G.utility = orig_utility
_G.actors_manager = orig_actors_manager
_G.my_utility = orig_my_utility
os.exit(0)
