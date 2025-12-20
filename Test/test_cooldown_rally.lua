-- Test that Rally respects spell_data cooldown and local recast guard
local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end

-- Stubs
local cast_calls = 0
_G.cast_spell = { self = function(spell_id, t)
    cast_calls = cast_calls + 1; return true
end }
package.loaded['utility'] = { is_spell_ready = function() return true end, is_spell_affordable = function() return true end, can_cast_spell = function() return true end }
_G.utility = package.loaded['utility']

local my_utility = require('my_utility/my_utility')
local spells_rally = require('spells/rally')

-- Configure menu
spells_rally.menu_elements.main_boolean = { get = function() return true end }
spells_rally.menu_elements.cast_on_cooldown = { get = function() return false end }
spells_rally.menu_elements.cast_delay = { get = function() return 0.1 end }

-- Ensure permissive is_spell_allowed wrapper in utility for this test
my_utility.is_spell_allowed = function(...) return true end

-- Ensure module starts with no recent casts
spells_rally.set_next_time_allowed_cast(0)

-- Test 1: initial cast should succeed
TIME_NOW = 0
local ok1 = spells_rally.logics()
if not ok1 then
    print('TEST FAIL: initial rally cast failed')
    os.exit(1)
end

-- Test 2: local 6s guard should block recast before 6s
TIME_NOW = 5
local ok2 = spells_rally.logics()
if ok2 then
    print('TEST FAIL: rally allowed to recast within 6s duration guard')
    os.exit(2)
end

-- Test 3: after 6s but before cooldown (cooldown is 16s), should still be blocked by cooldown enforcement
TIME_NOW = 10
local ok3 = spells_rally.logics()
if ok3 then
    print('TEST FAIL: rally allowed to cast before spell cooldown')
    os.exit(3)
end

-- Test 4: after cooldown elapsed, should allow cast
TIME_NOW = 17
local ok4 = spells_rally.logics()
if not ok4 then
    print('TEST FAIL: rally did not cast after cooldown elapsed')
    os.exit(4)
end

print('ALL TESTS PASS')
os.exit(0)
