local my_utility = require('my_utility/my_utility')

-- Save globals to restore
local orig_get_local_player = _G.get_local_player
local orig_package_utility = package.loaded['utility']
local orig_cast_spell = _G.cast_spell

-- Mock player with buffs
_G.get_local_player = function()
    return {
        get_buffs = function()
            -- Mock a buff with name_hash=123, type=2, stacks=1
            return {
                { name_hash = 123, type = 2, stacks = 1, get_remaining_time = function() return 1 end }
            }
        end
    }
end

-- Test is_buff_active returns true when buff present
local ok = my_utility.is_buff_active(123, 2)
if not ok then
    print('TEST FAIL: is_buff_active should return true when buff present')
    os.exit(1)
end

-- Test buff_stack_count returns correct stacks
local stacks = my_utility.buff_stack_count(123, 2)
if stacks ~= 1 then
    print('TEST FAIL: buff_stack_count expected 1 got', stacks)
    os.exit(1)
end

print('TEST PASS: is_buff_active and buff_stack_count positive case')

-- Test negative case (no buffs)
_G.get_local_player = function()
    return { get_buffs = function() return {} end }
end
if my_utility.is_buff_active(123, 2) then
    print('TEST FAIL: is_buff_active returned true when no buffs')
    os.exit(1)
end
if my_utility.buff_stack_count(123, 2) ~= 0 then
    print('TEST FAIL: buff_stack_count should be 0 when no buffs')
    os.exit(1)
end

print('TEST PASS: is_buff_active and buff_stack_count negative case')

-- Test try_cast_spell when utility says spell not ready
package.loaded['utility'] = { is_spell_ready = function() return false end }
local cast_fn_called = false
local cast_ok, delay = my_utility.try_cast_spell('test', 999, true, 0, function()
    cast_fn_called = true; return true
end, 0.1)
if cast_ok then
    print('TEST FAIL: try_cast_spell should return false when utility.is_spell_ready=false')
    os.exit(1)
end
if cast_fn_called then
    print('TEST FAIL: cast function should NOT be called when not ready')
    os.exit(1)
end
print('TEST PASS: try_cast_spell respects utility.is_spell_ready==false')

-- Test try_cast_spell success path
package.loaded['utility'] = { is_spell_ready = function() return true end }
_G.cast_spell = { self = function(spell_id, t) return true end }
local cast_ok2, delay2 = my_utility.try_cast_spell('test', 999, true, 0, function() return true end, 0.5)
if not cast_ok2 or not delay2 then
    print('TEST FAIL: try_cast_spell success path failed', cast_ok2, delay2)
    os.exit(1)
end
print('TEST PASS: try_cast_spell success path returned', cast_ok2, delay2)

-- Restore globals
_G.get_local_player = orig_get_local_player
package.loaded['utility'] = orig_package_utility
_G.cast_spell = orig_cast_spell

os.exit(0)
