-- Test Purify returns cooldown on success

local spells = require('spells/purify')

-- Stub environment
package.loaded['utility'] = { is_spell_ready = function() return true end }
_G.cast_spell = { self = function(spell_id, t) return true end }

spells.menu_elements.main_boolean = { get = function() return true end }
spells.menu_elements.cast_delay = { get = function() return 0.33 end }

if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

local ok, cooldown = spells.logics()
if not ok then
    print('TEST FAIL: purify.logics should succeed')
    os.exit(1)
end
if type(cooldown) ~= 'number' then
    print('TEST FAIL: purify should return numeric cooldown')
    os.exit(1)
end
if math.abs(cooldown - 0.33) > 1e-6 then
    print('TEST FAIL: purify cooldown expected 0.33 got', cooldown)
    os.exit(1)
end

print('TEST PASS: purify returns cooldown', cooldown)

-- cleanup
package.loaded['utility'] = nil
_G.cast_spell = nil
os.exit(0)