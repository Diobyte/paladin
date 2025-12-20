local my_utility = require('my_utility/my_utility')

-- Mock environment
cast_spell = { self = function(spell_id, t) return true end }
utility = { is_spell_ready = function(spell_id) return true end }

local menu = { cast_on_cooldown = { get = function() return true end } }

-- Success path
local ok, delay = my_utility.try_maintain_buff('test_buff', 1234, menu, 0.2)
if not ok or math.abs(delay - 0.2) > 1e-6 then
    print('TEST FAILED: expected true,0.2 got', ok, delay)
    os.exit(1)
end
print('TEST PASSED: try_maintain_buff returned', ok, delay)

-- Failure: utility says spell not ready
cast_spell = { self = function(spell_id, t) return true end }
utility = { is_spell_ready = function(spell_id) return false end }
local ok2, delay2 = my_utility.try_maintain_buff('test_buff', 1234, menu, 0.2)
if ok2 ~= false then
    print('TEST FAILED: expected false when utility.is_spell_ready=false got', ok2, delay2)
    os.exit(2)
end
print('TEST PASSED: try_maintain_buff returned false when utility.is_spell_ready=false')

-- Failure: cast fails (cast_spell returns false)
cast_spell = { self = function(spell_id, t) return false end }
utility = { is_spell_ready = function(spell_id) return true end }
local ok3, delay3 = my_utility.try_maintain_buff('test_buff', 1234, menu, 0.2)
if ok3 ~= false then
    print('TEST FAILED: expected false when cast_spell returns false got', ok3, delay3)
    os.exit(3)
end
print('TEST PASSED: try_maintain_buff returned false when cast_spell failed')

-- Nil return: menu option disabled
local menu2 = { cast_on_cooldown = { get = function() return false end } }
local ok4 = my_utility.try_maintain_buff('test_buff', 1234, menu2, 0.2)
if ok4 ~= nil then
    print('TEST FAILED: expected nil when menu option disabled got', ok4)
    os.exit(4)
end
print('TEST PASSED: try_maintain_buff returned nil when menu disabled')

os.exit(0)
