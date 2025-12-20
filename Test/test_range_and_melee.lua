local assert = require('Test/assert')
local my_utility = require('my_utility/my_utility')

-- Stub player position to simulate distance behavior
local player_pos = {}
function player_pos:squared_dist_to_ignore_z(target_pos)
    return target_pos._dist_sq
end

_G.get_player_position = function() return player_pos end

local target = { get_position = function() return { _dist_sq = 25 } end }
-- range 5 -> range^2 = 25; is_in_range uses < so exact equality should be false
local in_range = my_utility.is_in_range(target, 5)
assert.assert_false(in_range, "is_in_range should be false when distance == range")

-- slightly inside
target = { get_position = function() return { _dist_sq = 24.999 } end }
local in_range2 = my_utility.is_in_range(target, 5)
assert.assert_true(in_range2, "is_in_range should be true when distance < range")

-- melee range
assert.assert_equal(2, my_utility.get_melee_range(), "default melee range should be 2")

print('TEST PASS: test_range_and_melee')
