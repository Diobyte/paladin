-- Test try_cast_spell respects CDR cap (75%) when computing effective cooldown

package.loaded['my_utility/spell_data'] = { testspell2 = { cooldown = 10 } }

-- Mock local player with an item that provides 80% CDR (should be capped to 75)
_G.get_local_player = function()
    return {
        get_equipped_items = function()
            return {
                { get_affixes = function() return { { get_name = function() return 'Cooldown Reduction' end, get_roll = function() return 80 end } } end }
            }
        end
    }
end

local current_time = 100
_G.get_time_since_inject = function() return current_time end
package.loaded['utility'] = { is_spell_ready = function() return true end }

local my_utility = require('my_utility/my_utility')

-- record a cast at time 100
my_utility.record_spell_cast('testspell2')

-- at time 102 effective cd = 10 * (1 - 0.75) = 2.5 => last + eff = 102.5 so time 102 should be blocked
current_time = 102
local ok = my_utility.try_cast_spell('testspell2', 999, true, 0, function() return true end, 0.1)
if ok then
    print('TEST FAIL: try_cast_spell should respect CDR cap and prevent cast at 102')
    os.exit(1)
end

-- at time 103 it should allow
current_time = 103
local ok2 = my_utility.try_cast_spell('testspell2', 999, true, 0, function() return true end, 0.1)
if not ok2 then
    print('TEST FAIL: try_cast_spell should allow cast after capped CDR cooldown')
    os.exit(1)
end

print('TEST PASS: try_cast_spell enforces CDR cap correctly')

-- cleanup
package.loaded['my_utility/spell_data'] = nil
package.loaded['utility'] = nil
_G.get_local_player = nil
_G.get_time_since_inject = nil
os.exit(0)
