-- Test Fortress cooldown behavior
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end

local spells = require('spells/fortress')
local my_utility = require('my_utility/my_utility')
my_utility.is_spell_allowed = function(...) return true end

_G.cast_spell = { self = function(spell_id, t) return true end }

if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

-- Use direct try_cast_spell
local sdmod = require('my_utility/spell_data')
local ok, delay = my_utility.try_cast_spell('fortress', sdmod.fortress.spell_id, true, 0,
    function() return cast_spell.self(sdmod.fortress.spell_id, 0) end, 0.1)
if not ok then
    print('TEST FAIL: fortress direct try_cast failed')
    os.exit(1)
end
print('TEST PASS: fortress direct try_cast success')
os.exit(0)
