-- Prepare stubs if necessary (tests run outside game environment)
package.loaded['my_utility/my_utility'] = package.loaded['my_utility/my_utility'] or require('my_utility/my_utility')

local ok, get_spell_priority = pcall(require, 'spell_priority')
if not ok then
    print('TEST FAIL: could not require spell_priority:', get_spell_priority)
    os.exit(1)
end

-- Use the real base priority for more realistic tests
local base = get_spell_priority.get_base_spell_priority(0)
local function find_index(tbl, val)
    for i, v in ipairs(tbl) do if v == val then return i end end
    return nil
end

local base_fan_idx = find_index(base, 'fanaticism_aura')
if not base_fan_idx then
    print('TEST FAIL: base missing fanaticism_aura')
    os.exit(1)
end

-- Mock get_local_player to return high attack speed affix
local orig_get_local_player = _G.get_local_player
local orig_utility = _G.utility
local orig_actors_manager = _G.actors_manager

_G.utility = { is_spell_ready = function() return true end }
_G.actors_manager = { get_enemy_actors = function() return {} end }

_G.get_local_player = function()
    return {
        get_equipped_items = function()
            return {
                { get_affixes = function() return { { get_name = function() return 'Attack Speed' end, get_roll = function() return 60 end } } end }
            }
        end
    }
end

_G.DEBUG_SPELL_PRIORITY_PREFILL = true
local adjusted_prefill = get_spell_priority.adjust_priorities_for_items(base)
_G.DEBUG_SPELL_PRIORITY_PREFILL = nil

-- DEBUG: print prefill table
if rawget(_G, 'DEBUG_SPELL_PRIORITY') then
    print('Prefill priorities (indices):')
    for i = 1, #adjusted_prefill do print(i, tostring(adjusted_prefill[i])) end
end

local function find_index_in_prefill(tbl, name)
    for i = 1, #tbl do if tbl[i] == name then return i end end
    return nil
end

local adj_fan_idx = find_index_in_prefill(adjusted_prefill, 'fanaticism_aura')
if not adj_fan_idx then
    print('TEST FAIL: adjusted missing fanaticism_aura')
    os.exit(1)
end

if adj_fan_idx <= base_fan_idx then
    print('TEST FAIL: fanaticism_aura did not move down with high attack speed (base idx', base_fan_idx,
        'adj prefill idx', adj_fan_idx, ')')
    os.exit(1)
end

print('TEST PASS: fanaticism_aura moved down with high attack speed (', base_fan_idx, '->', adj_fan_idx, ')')

-- Test CDR boosts ultimate priority (use prefill return)
_G.get_local_player = function()
    return {
        get_equipped_items = function()
            return {
                { get_affixes = function() return { { get_name = function() return 'Cooldown Reduction' end, get_roll = function() return 25 end } } end }
            }
        end
    }
end

_G.DEBUG_SPELL_PRIORITY_PREFILL = true
local adjusted2_prefill = get_spell_priority.adjust_priorities_for_items(base)
_G.DEBUG_SPELL_PRIORITY_PREFILL = nil

local function find_index_in_prefill(tbl, name)
    for i = 1, #tbl do if tbl[i] == name then return i end end
    return nil
end

local base_ult_idx = find_index(base, 'arbiter_of_justice')
local adj_ult_prefill_idx = find_index_in_prefill(adjusted2_prefill, 'arbiter_of_justice')
if not base_ult_idx or not adj_ult_prefill_idx then
    print('TEST FAIL: arbiter missing')
    os.exit(1)
end
if adj_ult_prefill_idx >= base_ult_idx then
    print('TEST FAIL: arbiter_of_justice did not move up with high CDR (base idx', base_ult_idx, 'adj prefill idx',
        adj_ult_prefill_idx, ')')
    os.exit(1)
end

print('TEST PASS: arbiter_of_justice moved up with high CDR (', base_ult_idx, '->', adj_ult_prefill_idx, ')')

-- Restore global
_G.get_local_player = orig_get_local_player
_G.utility = orig_utility
_G.actors_manager = orig_actors_manager
os.exit(0)
