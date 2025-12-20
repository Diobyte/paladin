local my_utility = require('my_utility/my_utility')
local spell_data = require('my_utility/spell_data')

-- Setup: ensure utility says spell ready and basic environment
package.loaded['utility'] = { is_spell_ready = function() return true end }

-- Use a real spell with cooldown (spear_of_the_heavens has cooldown defined in spell_data)
local spell_name = 'spear_of_the_heavens'
local spell_id = spell_data[spell_name].spell_id

-- Ensure clean state
-- provide a fake get_time_since_inject for test environments if missing
local orig_time = _G.get_time_since_inject
if type(orig_time) ~= 'function' then
    _G.get_time_since_inject = function() return 0 end
end

-- Record a cast and verify immediate re-cast is rejected
my_utility.record_spell_cast(spell_name)
local ok = my_utility.try_cast_spell(spell_name, spell_id, true, 0, function() return true end, 0.1)
if ok then
    local last = my_utility.get_last_cast_time(spell_name)
    print('DEBUG: last=', last, 'cooldown=', spell_data[spell_name].cooldown, 'time=',
        (type(get_time_since_inject) == 'function' and get_time_since_inject() or 'nil'))
    print('TEST FAIL: try_cast_spell should return false when internal cooldown not expired')
    os.exit(1)
end

-- Now simulate time advancing past cooldown by mocking get_time_since_inject
local last = my_utility.get_last_cast_time(spell_name)
_G.get_time_since_inject = function() return last + (spell_data[spell_name].cooldown or 0) + 1 end
-- Now attempt cast again, should pass
local ok2, delay = my_utility.try_cast_spell(spell_name, spell_id, true, 0, function() return true end, 0.1)
-- restore time function
if type(orig_time) == 'function' then _G.get_time_since_inject = orig_time else _G.get_time_since_inject = nil end

if not ok2 then
    print('TEST FAIL: try_cast_spell should return true when cooldown expired')
    os.exit(1)
end
print('TEST PASS: cooldown enforcement for', spell_name)
os.exit(0)
