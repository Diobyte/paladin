-- Test try_cast_spell respects item cooldown reduction (CDR)

-- Set up fake spell_data before requiring my_utility (module caches it at load time)
package.loaded['my_utility/spell_data'] = { testspell = { cooldown = 10 } }

-- Mock local player with equipped items that provide Cooldown Reduction affix
_G.get_local_player = function()
    return {
        get_equipped_items = function()
            return {
                { get_affixes = function() return { { get_name = function() return 'Cooldown Reduction' end, get_roll = function() return 50 end } } end }
            }
        end
    }
end

-- Stub time and utility
_G.get_time_since_inject = function() return 100 end
package.loaded['utility'] = { is_spell_ready = function() return true end }

local my_utility = require('my_utility/my_utility')

-- Record a cast at time 100
my_utility.record_spell_cast('testspell')

-- Now set time to 104: effective cooldown = 10 * (1 - 0.5) = 5 -> last + eff = 105. At 104 we should NOT be allowed to cast
_G.get_time_since_inject = function() return 104 end
local cast_ok = my_utility.try_cast_spell('testspell', 999, true, 0, function() return true end, 0.1)
if cast_ok then
    print('TEST FAIL: try_cast_spell should respect reduced cooldown and prevent cast at 104')
    os.exit(1)
end

-- Advance time to 106: now it's beyond the reduced cooldown
_G.get_time_since_inject = function() return 106 end
local cast_ok2, delay2 = my_utility.try_cast_spell('testspell', 999, true, 0, function() return true end, 0.1)
if not cast_ok2 then
    print('TEST FAIL: try_cast_spell should allow cast after reduced cooldown')
    os.exit(1)
end

print('TEST PASS: try_cast_spell enforces CDR-adjusted internal cooldown')

-- Cleanup: restore loaded modules
package.loaded['my_utility/spell_data'] = nil
package.loaded['utility'] = nil
_G.get_local_player = nil
_G.get_time_since_inject = nil

os.exit(0)
