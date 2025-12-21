-- Test Aegis cooldown behavior
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end
_G.get_local_player = function() return { get_current_health = function() return 10 end, get_max_health = function() return 100 end } end

local spells = require('spells/aegis')
local my_utility = require('my_utility/my_utility')
-- Provide permissive utility and orbwalker stubs
local util_stub = { is_spell_ready = function() return true end, is_spell_affordable = function() return true end, can_cast_spell = function() return true end }
package.loaded['utility'] = util_stub
_G.utility = util_stub
local orb_stub = { get_orb_mode = function() return 1 end }
package.loaded['orbwalker'] = orb_stub
_G.orbwalker = orb_stub
_G.orb_mode = { none = 0, pvp = 1, clear = 2 }
local auto_play_stub = { is_active = function() return false end, get_objective = function() return 0 end }
package.loaded['auto_play'] = auto_play_stub
_G.auto_play = auto_play_stub
local objective_stub = { fight = 1 }
package.loaded['objective'] = objective_stub
_G.objective = objective_stub
_G.get_local_player = function() return { get_buffs = function() return {} end, get_active_spell_id = function() return 0 end, get_equipped_items = function() return {} end, get_current_health = function() return 10 end, get_max_health = function() return 100 end, get_position = function() return { x = 0, y = 0, z = 0 } end } end
local evade_stub = { is_dangerous_position = function() return false end }
package.loaded['evade'] = evade_stub
_G.evade = evade_stub

_G.cast_spell = { self = function(spell_id, t) return true end }

if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

TIME_NOW = 0
if not spells.logics() then
    print('TEST FAIL: aegis first cast failed')
    os.exit(1)
end
TIME_NOW = 0.05
if spells.logics() then
    print('TEST FAIL: aegis allowed early recast')
    os.exit(2)
end
TIME_NOW = 0.2
if not spells.logics() then
    print('TEST FAIL: aegis did not cast after delay')
    os.exit(3)
end

print('TEST PASS: aegis cooldown behavior')
os.exit(0)
