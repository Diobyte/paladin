-- Test Shield Charge cooldown and weave guard
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.combo_box = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.slider_int = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end
_G.get_player_position = function() return { x = 0, y = 0, z = 0 } end

local spells = require('spells/shield_charge')
local my_utility = require('my_utility/my_utility')
my_utility.is_spell_allowed = function(...) return true end
my_utility.is_in_range = function(target, range) return true end

local boss_target = { get_position = function() return { x = 0, y = 0, z = 0 } end, is_elite = function() return false end, is_boss = function() return true end }
_G.cast_spell = { position = function(id, pos, t) return true end }

if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

-- First cast
TIME_NOW = 0
if not spells.logics(boss_target) then
    print('TEST FAIL: shield_charge first cast failed')
    os.exit(1)
end
-- Within 2s weave guard should block
TIME_NOW = 1
if spells.logics(boss_target) then
    print('TEST FAIL: shield_charge allowed to cast within weave guard')
    os.exit(2)
end
-- After 2s but before cast_delay, blocked by cast delay
TIME_NOW = 3
if spells.logics(boss_target) then
    print('TEST FAIL: shield_charge allowed too early before cooldown')
    os.exit(3)
end
-- After desired cooldown (use cast_delay 0.1) set to 4 to be safe
TIME_NOW = 4
if not spells.logics(boss_target) then
    print('TEST FAIL: shield_charge did not cast after cooldown')
    os.exit(4)
end

print('TEST PASS: shield_charge behavior')
os.exit(0)
