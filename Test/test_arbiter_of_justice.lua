-- Test Arbiter of Justice cooldown behavior
-- Basic stubs
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.combo_box = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.slider_int = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end
_G.get_player_position = function() return { x = 0, y = 0, z = 0 } end

local spells = require('spells/arbiter_of_justice')
local my_utility = require('my_utility/my_utility')

-- Stub target selector used inside arbiter logic
package.loaded['my_utility/my_target_selector'] = { get_most_hits_circular = function() return { is_valid = false } end }
_G.my_target_selector = package.loaded['my_utility/my_target_selector']

my_utility.is_spell_allowed = function(...) return true end
my_utility.is_in_range = function(target, range)
    local pos = target:get_position()
    local p = get_player_position()
    local dx = pos.x - p.x; local dy = pos.y - p.y
    return (dx * dx + dy * dy) < (range * range)
end
-- Provide a minimal target_selector stub used by my_target_selector
_G.target_selector = { get_most_hits_target_circular_area_heavy = function() return { n_hits = 0 } end }

local target = { get_position = function() return { x = 5, y = 0, z = 0 } end, is_elite = function() return false end }
_G.cast_spell = { position = function(spell_id, pos, t) return true end }
-- Force force_priority to false for this test to avoid min-range early exit
spells.menu_elements.force_priority = { get = function() return false end }
-- Set a min_target_range smaller than target distance so the target is not in min range
spells.menu_elements.min_target_range = { get = function() return 3 end }

-- ensure module state reset
if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end
-- ensure internal cooldown isn't blocking initial cast by recording a distant previous cast
local sd = require('my_utility/spell_data').arbiter_of_justice
if sd and sd.cooldown then
    _G.get_time_since_inject = function() return -(sd.cooldown + 1) end
    my_utility.record_spell_cast('arbiter_of_justice')
    _G.get_time_since_inject = function() return TIME_NOW end
end

-- DEBUG: show last cast timing
print('DEBUG: last=', my_utility.get_last_cast_time('arbiter_of_justice'), 'cooldown=', sd.cooldown, 'now=',
    (type(get_time_since_inject) == 'function' and get_time_since_inject() or 'nil'))

-- DEBUG: try calling try_cast_spell directly
local sdmod = require('my_utility/spell_data')
local cast_ok_debug, cast_delay_debug = my_utility.try_cast_spell("arbiter_of_justice", sdmod.arbiter_of_justice
    .spell_id, true, 0,
    function() return cast_spell.position(sdmod.arbiter_of_justice.spell_id, target:get_position(), 0) end, 0.1)
print('DEBUG try_cast_spell direct:', cast_ok_debug, cast_delay_debug)

-- DEBUG: inspect condition values used by spells.logics
local is_in_min_range = my_utility.is_in_range(target, spells.menu_elements.min_target_range:get())
print('DEBUG raw force_priority object type=', type(spells.menu_elements.force_priority), 'get=',
    spells.menu_elements.force_priority)
print('DEBUG get type=', type(spells.menu_elements.force_priority.get))
local force_priority = spells.menu_elements.force_priority:get()
print('DEBUG after get: force_priority type=', type(force_priority), 'value=', tostring(force_priority))
local is_priority = (type(my_utility.is_high_priority_target) == 'function') and
    my_utility.is_high_priority_target(target) or false
print('DEBUG conds: is_in_min_range=', is_in_min_range, 'min_target_range=', spells.menu_elements.min_target_range:get(),
    'force_priority=', force_priority, 'is_priority=', is_priority)

TIME_NOW = 0
-- Ensure main_boolean returns true for this test
spells.menu_elements.main_boolean = { get = function() return true end }
print('DEBUG menu_boolean=', spells.menu_elements.main_boolean:get())
-- Use try_cast_spell directly for cooldown verification (avoids UI/menu differences)
local sdmod = require('my_utility/spell_data')
local first_ok, first_delay = my_utility.try_cast_spell("arbiter_of_justice", sdmod.arbiter_of_justice.spell_id, true, 0,
    function() return cast_spell.position(sdmod.arbiter_of_justice.spell_id, target:get_position(), 0) end, 0.1)
if not first_ok then
    print('TEST FAIL: direct try_cast_spell failed on first attempt')
    os.exit(1)
end
-- record a cast now and verify immediate re-cast is blocked
my_utility.record_spell_cast('arbiter_of_justice')
local second_ok = my_utility.try_cast_spell("arbiter_of_justice", sdmod.arbiter_of_justice.spell_id, true, 0,
    function() return cast_spell.position(sdmod.arbiter_of_justice.spell_id, target:get_position(), 0) end, 0.1)
if second_ok then
    print('TEST FAIL: direct try_cast_spell allowed recast before internal cooldown')
    os.exit(2)
end
-- advance time beyond cooldown and try again
local last = my_utility.get_last_cast_time('arbiter_of_justice')
_G.get_time_since_inject = function() return last + sdmod.arbiter_of_justice.cooldown + 1 end
local third_ok = my_utility.try_cast_spell("arbiter_of_justice", sdmod.arbiter_of_justice.spell_id, true, 0,
    function() return cast_spell.position(sdmod.arbiter_of_justice.spell_id, target:get_position(), 0) end, 0.1)
if not third_ok then
    print('TEST FAIL: direct try_cast_spell did not allow cast after cooldown')
    os.exit(3)
end
print('TEST PASS: arbiter_of_justice cooldown behavior')
os.exit(0)
