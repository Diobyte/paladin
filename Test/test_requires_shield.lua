local my_utility = require('my_utility/my_utility')

-- Save original get_local_player
local orig_get_local_player = _G.get_local_player

-- Test no equipped items
_G.get_local_player = function()
    return { get_equipped_items = function() return {} end }
end
if my_utility.has_shield() then
    print('TEST FAIL: has_shield returned true with no equipped items')
    os.exit(1)
end
print('TEST PASS: has_shield false with no items')

-- Test with a shield
_G.get_local_player = function()
    return {
        get_equipped_items = function()
            return {
                { get_name = function() return 'Sturdy Shield' end }
            }
        end
    }
end
if not my_utility.has_shield() then
    print('TEST FAIL: has_shield returned false with a shield equipped')
    os.exit(1)
end
print('TEST PASS: has_shield true with shield equipped')

-- Restore
_G.get_local_player = orig_get_local_player
os.exit(0)
