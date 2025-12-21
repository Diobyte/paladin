local sd = require('my_utility/spell_data')
local consecration = require('spells/consecration')
local my_utility = require('my_utility/my_utility')

-- Stub environment
package.loaded['utility'] = { is_spell_ready = function() return true end }
_G.cast_spell = { self = function(spell_id, t) return true end }
_G.get_time_since_inject = function() return 100 end

local ok, cooldown = consecration.logics()
if not ok then
    print('TEST FAIL: consecration.logics should return true when cast succeeds')
    os.exit(1)
end
if type(cooldown) ~= 'number' then
    print('TEST FAIL: consecration.logics should return cooldown as number')
    os.exit(1)
end

print('TEST PASS: consecration.logics returns success and cooldown (', cooldown, ')')

-- cleanup
package.loaded['utility'] = nil
_G.cast_spell = nil
_G.get_time_since_inject = nil
os.exit(0)
