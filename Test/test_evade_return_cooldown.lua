-- Test Evade returns a cooldown based on user delay and minimum thresholds
local spells_evade = require('spells/evade')

-- Stubs
_G.get_time_since_inject = function() return 0 end
package.loaded['utility'] = { is_spell_ready = function() return true end }
_G.cast_spell = { position = function(spell_id, pos, t) return true end }

-- Configure menu to use user delay 0.2 (above manual min 0.1)
spells_evade.menu_elements.cast_delay = { get = function() return 0.2 end }

-- Ensure module-level next time is reset
spells_evade.set_next_time_allowed_cast(0)

-- Ensure auto-play disabled
package.loaded['my_utility/my_utility'].is_auto_play_enabled = function() return false end

local ok, cooldown = spells_evade.logics(nil)
if not ok then
    print('TEST FAIL: Evade should have cast')
    os.exit(1)
end
if type(cooldown) ~= 'number' then
    print('TEST FAIL: Evade should return a numeric cooldown')
    os.exit(1)
end
if math.abs(cooldown - 0.2) > 1e-6 then
    print('TEST FAIL: Evade cooldown expected 0.2 got', cooldown)
    os.exit(1)
end

print('TEST PASS: Evade returns expected cooldown (', cooldown, ')')

-- cleanup
package.loaded['utility'] = nil
_G.cast_spell = nil
_G.get_time_since_inject = nil
os.exit(0)
