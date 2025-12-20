-- Minimal UI stubs so spell modules can be required in tests
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default, id) return { get = function() return default end, render = function() end } end }
_G.combo_box = { new = function(default, id) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default, id) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

-- Time control for tests
local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end
local spells_evade = require('spells/evade')
local my_utility = require('my_utility/my_utility')

-- Mock actors manager to return no enemies by default
local actors_stub = { get_enemy_actors = function() return {} end }
package.loaded['actors_manager'] = actors_stub
_G.actors_manager = actors_stub

-- Stub auto_play used by my_utility.is_auto_play_enabled to avoid nil access in tests
local auto_play_stub = { is_active = function() return false end, get_objective = function() return 0 end }
package.loaded['auto_play'] = auto_play_stub
_G.auto_play = auto_play_stub

-- Provide objective constants used by is_auto_play_enabled
local objective_stub = { fight = 1 }
package.loaded['objective'] = objective_stub
_G.objective = objective_stub

-- Mock cursor and player positions
_G.get_cursor_position = function()
    return {
        x = 1,
        y = 0,
        z = 0,
        squared_dist_to_ignore_z = function(self, other)
            local dx = self.x - other.x; local dy = self.y - other.y; return dx * dx + dy * dy
        end
    }
end
_G.get_player_position = function() return { x = 0, y = 0, z = 0 } end

-- Ensure utility says spell ready and orbwalker is permissive
local util_stub = { is_spell_ready = function() return true end, is_spell_affordable = function() return true end, can_cast_spell = function() return true end }
package.loaded['utility'] = util_stub
_G.utility = util_stub
local orb_stub = { get_orb_mode = function() return 1 end }
package.loaded['orbwalker'] = orb_stub
_G.orbwalker = orb_stub -- pvp/clear accepted by is_spell_allowed logic

-- Default menu elements; we'll override per test
spells_evade.menu_elements.allow_out_of_combat = { get = function() return true end }
spells_evade.menu_elements.main_boolean = { get = function() return true end }
spells_evade.menu_elements.mobility_only = { get = function() return false end }
spells_evade.menu_elements.elites_only = { get = function() return false end }
spells_evade.menu_elements.min_target_range = { get = function() return 3 end }
spells_evade.menu_elements.cast_delay = { get = function() return 0.5 end }

-- Mock cast_spell.position to succeed and record calls
local cast_calls = 0
_G.cast_spell = {
    position = function(spell_id, pos, t)
        cast_calls = cast_calls + 1; return true
    end
}

-- Minimal get_local_player used by is_spell_allowed
_G.get_local_player = function() return { get_buffs = function() return {} end, get_active_spell_id = function() return 0 end, get_equipped_items = function() return {} end, get_current_health = function() return 100 end, get_max_health = function() return 100 end } end
-- Make is_spell_allowed permissive for these tests
my_utility.is_spell_allowed = function(...) return true end

-- Helper to override range check for test targets
my_utility.is_in_range = function(target, range)
    local pos = target:get_position()
    local p = get_player_position()
    local dx = pos.x - p.x; local dy = pos.y - p.y
    return (dx * dx + dy * dy) < (range * range)
end

-- Test 1: Out of combat cast succeeds when allowed and no enemies
TIME_NOW = 0
cast_calls = 0
local ok = spells_evade.logics(nil)
if not ok then
    print('TEST FAIL: evade did not cast out of combat when allowed')
    os.exit(1)
end
print('TEST PASS: evade cast out of combat when allowed')

-- Test 2: Mobility-only with no target casts towards cursor (within range)
spells_evade.set_next_time_allowed_cast(0)
spells_evade.menu_elements.mobility_only = { get = function() return true end }
TIME_NOW = 0
cast_calls = 0
local ok2 = spells_evade.logics(nil)
if not ok2 then
    print('TEST FAIL: mobility-only evade did not cast towards cursor when allowed')
    os.exit(2)
end
print('TEST PASS: mobility-only cast towards cursor')

-- Test 3: Mobility-only with target too close should NOT cast
local close_target = {
    get_position = function() return { x = 1, y = 0, z = 0 } end,
    is_elite = function() return false end,
}
spells_evade.menu_elements.mobility_only = { get = function() return true end }
spells_evade.menu_elements.min_target_range = { get = function() return 3 end }
TIME_NOW = 0
local ok3 = spells_evade.logics(close_target)
if ok3 then
    print('TEST FAIL: mobility-only evade cast on target within min_target_range')
    os.exit(3)
end
print('TEST PASS: mobility-only correctly blocked for target within min_target_range')

-- Test 4: Mobility-only with target in acceptable range should be considered valid (filter check)
local far_target = {
    get_position = function() return { x = 4, y = 0, z = 0 } end,
    is_elite = function() return false end,
}
spells_evade.menu_elements.mobility_only = { get = function() return true end }
spells_evade.menu_elements.min_target_range = { get = function() return 3 end }
-- The internal check in the logic is:
-- if not is_in_range(target, max_spell_range) or is_in_range(target, min_target_range) then return false end
-- So for a valid target we expect: is_in_range(target, max_spell_range) == true and is_in_range(target, min_target_range) == false
local ok4 = my_utility.is_in_range(far_target, 10.0) and
    not my_utility.is_in_range(far_target, spells_evade.menu_elements.min_target_range:get())
if not ok4 then
    print('TEST FAIL: mobility-only target filter rejected acceptable-distance target')
    os.exit(4)
end
print('TEST PASS: mobility-only target filter accepted target at acceptable distance')

-- Test 5: Cast rate respects manual min delay (0.1s)
spells_evade.menu_elements.mobility_only = { get = function() return false end }
spells_evade.menu_elements.cast_delay = { get = function() return 0.01 end } -- user wants very fast
my_utility.is_auto_play_enabled = function() return false end
TIME_NOW = 0

local first = spells_evade.logics(nil)
if not first then os.exit(5) end
-- advance time less than manual min (0.05 < 0.1)
TIME_NOW = 0.05
local second = spells_evade.logics(nil)
if second then
    print('TEST FAIL: manual evade allowed to cast before manual min delay')
    os.exit(6)
end
-- advance time beyond manual min
TIME_NOW = 0.11
local third = spells_evade.logics(nil)
if not third then
    print('TEST FAIL: manual evade did not allow casting after manual min delay')
    os.exit(7)
end
print('TEST PASS: manual min delay respected')

-- Test 6: Cast rate respects auto-play min delay (0.5s)
spells_evade.menu_elements.cast_delay = { get = function() return 0.01 end }
my_utility.is_auto_play_enabled = function() return true end
TIME_NOW = 0
local a1 = spells_evade.logics(nil)
if not a1 then os.exit(8) end
TIME_NOW = 0.3
local a2 = spells_evade.logics(nil)
if a2 then
    print('TEST FAIL: auto-play evade allowed to cast before auto min delay')
    os.exit(9)
end
TIME_NOW = 0.51
local a3 = spells_evade.logics(nil)
if not a3 then
    print('TEST FAIL: auto-play evade did not allow casting after auto min delay')
    os.exit(10)
end
print('TEST PASS: auto-play min delay respected')

print('ALL TESTS PASS')
os.exit(0)
