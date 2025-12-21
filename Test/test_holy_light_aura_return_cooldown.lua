local spells = require('spells/holy_light_aura')

-- Stub environment
package.loaded['utility'] = { is_spell_ready = function() return true end }
_G.cast_spell = { self = function(spell_id, t) return true end }
_G.get_time_since_inject = function() return 170 end

-- Ensure menu enabled and reasonable delay
spells.menu_elements.main_boolean = { get = function() return true end }
spells.menu_elements.cast_delay = { get = function() return 0.4 end }
spells.menu_elements.max_cast_range = { get = function() return 10 end }

-- Reset internal next time guard
if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

-- Ensure enemies in range: stub enemy_count_simple
package.loaded['my_utility/my_utility'].enemy_count_simple = function() return 1 end

local ok, cooldown = spells.logics()
if not ok then
    print('TEST FAIL: holy_light_aura.logics should return true on successful cast')
    os.exit(1)
end
if type(cooldown) ~= 'number' then
    print('TEST FAIL: holy_light_aura.logics should return numeric cooldown')
    os.exit(1)
end
if math.abs(cooldown - 0.4) > 1e-6 then
    print('TEST FAIL: holy_light_aura.cooldown expected 0.4 got', cooldown)
    os.exit(1)
end

print('TEST PASS: holy_light_aura returns cooldown', cooldown)

-- cleanup
package.loaded['utility'] = nil
_G.cast_spell = nil
_G.get_time_since_inject = nil
package.loaded['my_utility/my_utility'].enemy_count_simple = nil
os.exit(0)
