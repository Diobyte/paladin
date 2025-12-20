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
my_utility.is_spell_allowed = function(...) return true end

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
