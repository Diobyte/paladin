-- Test that Heavens Fury respects spell_data cooldown
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
local spells = require('spells/heavens_fury')

-- Configure menu
spells.menu_elements.main_boolean = { get = function() return true end }
spells.menu_elements.elites_only = { get = function() return false end }
spells.menu_elements.cast_delay = { get = function() return 0.5 end }

-- Ensure permissive is_spell_allowed wrapper in utility for this test
my_utility.is_spell_allowed = function(...) return true end

-- Ensure module starts with no recent casts
spells.set_next_time_allowed_cast(0)

-- Test 1: initial cast should succeed
TIME_NOW = 0
local ok1 = spells.logics({ get_position = function() return { x = 1, y = 0, z = 0 } end, is_elite = function() return false end })
if not ok1 then
    print('TEST FAIL: initial Heavens Fury cast failed')
    os.exit(1)
end

-- Test 2: immediate recast should be blocked by next_time_allowed_cast
TIME_NOW = 0.1
local ok2 = spells.logics({ get_position = function() return { x = 1, y = 0, z = 0 } end, is_elite = function() return false end })
if ok2 then
    print('TEST FAIL: Heavens Fury allowed to recast too quickly')
    os.exit(2)
end

-- Test 3: after cooldown (30s) elapsed, should allow cast
TIME_NOW = 31
local ok3 = spells.logics({ get_position = function() return { x = 1, y = 0, z = 0 } end, is_elite = function() return false end })
if not ok3 then
    print('TEST FAIL: Heavens Fury did not cast after cooldown elapsed')
    os.exit(3)
end

print('ALL TESTS PASS')
os.exit(0)
