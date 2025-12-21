local my_utility = require('my_utility/my_utility')

local function make_obj_with_dot(dot_val)
    local obj = {}
    setmetatable(obj, {
        __sub = function(a,b)
            return {
                normalize = function()
                    -- return an object with a dot method that ignores the argument and returns dot_val
                    return { dot = function(_,_) return dot_val end }
                end
            }
        end
    })
    return obj
end

local origin = {} -- origin is unused by our test subtraction implementation

-- Case 1: dot slightly > 1 -> should be clamped to 1 -> angle 0 -> within small threshold
local ref = make_obj_with_dot(1.0000001)
local tgt = make_obj_with_dot(1.0)
local ok, res = pcall(function() return my_utility.is_target_within_angle(origin, ref, tgt, 1) end)
if not ok then
    print('TEST FAIL: is_target_within_angle errored for >1')
    os.exit(1)
end
if res ~= true then
    print('TEST FAIL: Expected true when dot >1 clamped to 1 (got', tostring(res), ')')
    os.exit(1)
end

-- Case 2: dot slightly < -1 -> should be clamped to -1 -> angle 180 -> not within 179
local ref2 = make_obj_with_dot(-1.0000001)
local tgt2 = make_obj_with_dot(-1.0)
local ok2, res2 = pcall(function() return my_utility.is_target_within_angle(origin, ref2, tgt2, 179) end)
if not ok2 then
    print('TEST FAIL: is_target_within_angle errored for <-1')
    os.exit(1)
end
if res2 ~= false then
    print('TEST FAIL: Expected false when dot <-1 clamped to -1 (got', tostring(res2), ')')
    os.exit(1)
end

-- Case 3: dot == 0 -> 90 degrees, threshold 90 should pass
local ref3 = make_obj_with_dot(0)
local tgt3 = make_obj_with_dot(0)
local ok3, res3 = pcall(function() return my_utility.is_target_within_angle(origin, ref3, tgt3, 90) end)
if not ok3 then
    print('TEST FAIL: is_target_within_angle errored for zero dot')
    os.exit(1)
end
if res3 ~= true then
    print('TEST FAIL: Expected true for 0 dot with 90deg threshold')
    os.exit(1)
end

print('TEST PASS: is_target_within_angle numeric stability OK')
os.exit(0)
