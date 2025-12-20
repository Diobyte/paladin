local spell_data = require('my_utility/spell_data')
local my_utility = require('my_utility/my_utility')

-- Test that certain spells have explicit cast_delay set in spell_data
local function assert_equal(a, b, message)
    if a ~= b then
        print('TEST FAIL:', message, 'expected', tostring(b), 'got', tostring(a))
        os.exit(1)
    end
end

assert_equal(spell_data.spear_of_the_heavens.cast_delay, 0.4, 'spear_of_the_heavens cast_delay')
assert_equal(spell_data.arbiter_of_justice.cast_delay, 1.0, 'arbiter_of_justice cast_delay')
assert_equal(spell_data.heavens_fury.cast_delay, 0.5, 'heavens_fury cast_delay')
assert_equal(spell_data.evade.cast_delay, 0.5, 'evade cast_delay')

-- Test default mapping for self cast type when cast_delay is not provided
local sd = spell_data.holy_light_aura
if sd and not sd.cast_delay and sd.cast_type == 'self' then
    local default = my_utility.spell_delays.instant_cast
    if default ~= 0.01 then
        print('TEST FAIL: expected default instant cast to be 0.01')
        os.exit(1)
    end
end

print('TEST PASS: delay selection and defaults look good')
os.exit(0)
