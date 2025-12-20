-- Test Zenith cooldown behavior
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end

local spells = require('spells/zenith')
local my_utility = require('my_utility/my_utility')
-- Use try_cast_spell directly for cooldown verification
local sdmod = require('my_utility/spell_data')
-- ensure internal cooldown isn't blocking initial cast by recording a distant previous cast
local sd = require('my_utility/spell_data').zenith
if sd and sd.cooldown then
    _G.get_time_since_inject = function() return -(sd.cooldown + 1) end
    my_utility.record_spell_cast('zenith')
    _G.get_time_since_inject = function() return TIME_NOW end
end

_G.cast_spell = { self = function(spell_id, t) return true end }

local first_ok, first_delay = my_utility.try_cast_spell("zenith", sdmod.zenith.spell_id, true, 0,
    function() return cast_spell.self(sdmod.zenith.spell_id, 0) end, 0.1)
if not first_ok then
    print('TEST FAIL: direct try_cast_spell failed on first attempt')
    os.exit(1)
end
my_utility.record_spell_cast('zenith')
local second_ok = my_utility.try_cast_spell("zenith", sdmod.zenith.spell_id, true, 0,
    function() return cast_spell.self(sdmod.zenith.spell_id, 0) end, 0.1)
if second_ok then
    print('TEST FAIL: direct try_cast_spell allowed recast before internal cooldown')
    os.exit(2)
end
local last = my_utility.get_last_cast_time('zenith')
_G.get_time_since_inject = function() return last + sdmod.zenith.cooldown + 1 end
local third_ok = my_utility.try_cast_spell("zenith", sdmod.zenith.spell_id, true, 0,
    function() return cast_spell.self(sdmod.zenith.spell_id, 0) end, 0.1)
if not third_ok then
    print('TEST FAIL: direct try_cast_spell did not allow cast after cooldown')
    os.exit(3)
end
print('TEST PASS: zenith cooldown behavior')
os.exit(0)
