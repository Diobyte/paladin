-- Test try_cast_spell records internal casts and enforces cooldowns

-- set up fake spell_data
package.loaded['my_utility/spell_data'] = { testspell = { cooldown = 2 } }
package.loaded['utility'] = { is_spell_ready = function() return true end }

_G.get_local_player = function()
    return { get_equipped_items = function() return {} end }
end

local current_time = 100
_G.get_time_since_inject = function() return current_time end

local my_utility = require('my_utility/my_utility')

-- First cast should succeed and be recorded internally
local ok, delay = my_utility.try_cast_spell('testspell', 999, true, 0, function() return true end, 0.1)
if not ok then
    print('TEST FAIL: initial cast should succeed')
    os.exit(1)
end

-- advance time but still before cooldown expiry
current_time = 101
local ok2 = my_utility.try_cast_spell('testspell', 999, true, 0, function() return true end, 0.1)
if ok2 then
    print('TEST FAIL: cast should be blocked due to internal cooldown')
    os.exit(1)
end

-- advance time past cooldown
current_time = 103
local ok3 = my_utility.try_cast_spell('testspell', 999, true, 0, function() return true end, 0.1)
if not ok3 then
    print('TEST FAIL: cast should be allowed after cooldown')
    os.exit(1)
end

print('TEST PASS: try_cast_spell records internal casts and enforces cooldowns')

-- cleanup
package.loaded['my_utility/spell_data'] = nil
package.loaded['utility'] = nil
_G.get_time_since_inject = nil
os.exit(0)
