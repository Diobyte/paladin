-- Test Blessed Shield returns cooldown when target is valid

local spells = require('spells/blessed_shield')

-- Stub environment
package.loaded['utility'] = { is_spell_ready = function() return true end }
_G.cast_spell = { target = function(target, spell_id, t) return true end }

-- Fake target
local fake_target = { is_elite = function() return true end }

-- Ensure menu enabled and delay
spells.menu_elements.main_boolean = { get = function() return true end }
spells.menu_elements.cast_delay = { get = function() return 0.12 end }

if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

local ok, cooldown = spells.logics(fake_target)
if not ok then
    print('TEST FAIL: blessed_shield.logics should succeed')
    os.exit(1)
end
if type(cooldown) ~= 'number' then
    print('TEST FAIL: blessed_shield should return numeric cooldown')
    os.exit(1)
end
if math.abs(cooldown - 0.12) > 1e-6 then
    print('TEST FAIL: blessed_shield cooldown expected 0.12 got', cooldown)
    os.exit(1)
end

print('TEST PASS: blessed_shield returns cooldown', cooldown)

-- cleanup
package.loaded['utility'] = nil
_G.cast_spell = nil
os.exit(0)