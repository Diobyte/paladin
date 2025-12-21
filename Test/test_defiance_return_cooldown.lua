local spells = require('spells/defiance_aura')

-- Stub environment
package.loaded['utility'] = { is_spell_ready = function() return true end }
_G.cast_spell = { self = function(spell_id, t) return true end }
_G.get_time_since_inject = function() return 160 end

-- Ensure menu enabled and reasonable delay
spells.menu_elements.main_boolean = { get = function() return true end }
spells.menu_elements.cast_delay = { get = function() return 0.30 end }

-- Reset internal next time guard
if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

local ok, cooldown = spells.logics()
if not ok then
    print('TEST FAIL: defiance_aura.logics should return true on successful cast')
    os.exit(1)
end
if type(cooldown) ~= 'number' then
    print('TEST FAIL: defiance_aura.logics should return numeric cooldown')
    os.exit(1)
end
if math.abs(cooldown - 0.30) > 1e-6 then
    print('TEST FAIL: defiance_aura.cooldown expected 0.30 got', cooldown)
    os.exit(1)
end

print('TEST PASS: defiance_aura returns cooldown', cooldown)

-- cleanup
package.loaded['utility'] = nil
_G.cast_spell = nil
_G.get_time_since_inject = nil
os.exit(0)
