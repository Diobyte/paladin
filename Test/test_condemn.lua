-- Test Condemn cooldown behavior
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.combo_box = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end
_G.get_player_position = function() return { x = 0, y = 0, z = 0 } end

local spells = require('spells/condemn')
local my_utility = require('my_utility/my_utility')
my_utility.is_spell_allowed = function(...) return true end
my_utility.is_in_range = function(target, range)
    local pos = target:get_position()
    local p = get_player_position()
    local dx = pos.x - p.x; local dy = pos.y - p.y
    return (dx * dx + dy * dy) < (range * range)
end

local target = { get_position = function() return { x = 4, y = 0, z = 0 } end, is_elite = function() return false end }
_G.cast_spell = { target = function(target, id, t, b) return true end, self = function(spell_id, t) return true end }

if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

-- Use direct try_cast_spell for cooldown verification
local sdmod = require('my_utility/spell_data')
-- ensure internal cooldown isn't blocking initial cast by recording a distant previous cast
local sd = require('my_utility/spell_data').condemn
if sd and sd.cooldown then
    _G.get_time_since_inject = function() return -(sd.cooldown + 1) end
    my_utility.record_spell_cast('condemn')
    _G.get_time_since_inject = function() return TIME_NOW end
end

local first_ok, first_delay = my_utility.try_cast_spell("condemn", sdmod.condemn.spell_id, true, 0,
    function() return cast_spell.self(sdmod.condemn.spell_id, 0) end, 0.1)
if not first_ok then
    print('TEST FAIL: direct try_cast_spell failed on first attempt')
    os.exit(1)
end
my_utility.record_spell_cast('condemn')
local second_ok = my_utility.try_cast_spell("condemn", sdmod.condemn.spell_id, true, 0,
    function() return cast_spell.self(sdmod.condemn.spell_id, 0) end, 0.1)
if second_ok then
    print('TEST FAIL: direct try_cast_spell allowed recast before internal cooldown')
    os.exit(2)
end
local last = my_utility.get_last_cast_time('condemn')
_G.get_time_since_inject = function() return last + sdmod.condemn.cooldown + 1 end
local third_ok = my_utility.try_cast_spell("condemn", sdmod.condemn.spell_id, true, 0,
    function() return cast_spell.self(sdmod.condemn.spell_id, 0) end, 0.1)
if not third_ok then
    print('TEST FAIL: direct try_cast_spell did not allow cast after cooldown')
    os.exit(3)
end
print('TEST PASS: condemn cooldown behavior')
os.exit(0)
