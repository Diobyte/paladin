-- Test Spear of the Heavens cooldown behavior
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.combo_box = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.slider_int = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end
_G.get_player_position = function() return { x = 0, y = 0, z = 0 } end

local spells = require('spells/spear_of_the_heavens')
local my_utility = require('my_utility/my_utility')
-- utility, orbwalker and auto_play stubs to allow is_spell_allowed to proceed
local util_stub = { is_spell_ready = function() return true end, is_spell_affordable = function() return true end, can_cast_spell = function() return true end }
package.loaded['utility'] = util_stub
_G.utility = util_stub
local orb_stub = { get_orb_mode = function() return 1 end }
package.loaded['orbwalker'] = orb_stub
_G.orbwalker = orb_stub
_G.orb_mode = { none = 0, pvp = 1, clear = 2 }
local auto_play_stub = { is_active = function() return false end, get_objective = function() return 0 end }
package.loaded['auto_play'] = auto_play_stub
_G.auto_play = auto_play_stub
local objective_stub = { fight = 1 }
package.loaded['objective'] = objective_stub
_G.objective = objective_stub
_G.get_local_player = function() return { get_buffs = function() return {} end, get_active_spell_id = function() return 0 end, get_equipped_items = function() return {} end, get_current_health = function() return 100 end, get_max_health = function() return 100 end, get_position = function() return { x = 0, y = 0, z = 0 } end } end
local evade_stub = { is_dangerous_position = function() return false end }
package.loaded['evade'] = evade_stub
_G.evade = evade_stub

my_utility.is_in_range = function(target, range)
    local pos = target:get_position()
    local p = get_player_position()
    local dx = pos.x - p.x; local dy = pos.y - p.y
    return (dx * dx + dy * dy) < (range * range)
end

local target = { get_position = function() return { x = 5, y = 0, z = 0 } end, is_elite = function() return false end }
_G.cast_spell = { position = function(spell_id, pos, t) return true end }
-- Ensure menu elements are permissive for this test
spells.menu_elements.main_boolean = { get = function() return true end }
spells.menu_elements.min_target_range = { get = function() return 0 end }
spells.menu_elements.elites_only = { get = function() return false end }
spells.menu_elements.cast_delay = { get = function() return 0.1 end }

if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

-- ensure internal cooldown isn't blocking initial cast by recording a distant previous cast
local sd = require('my_utility/spell_data').spear_of_the_heavens
if sd and sd.cooldown then
    _G.get_time_since_inject = function() return -(sd.cooldown + 1) end
    my_utility.record_spell_cast('spear_of_the_heavens')
    _G.get_time_since_inject = function() return TIME_NOW end
end

-- Debug direct try_cast_spell
local sdmod = require('my_utility/spell_data')
local direct_ok, direct_delay = my_utility.try_cast_spell("spear_of_the_heavens", sdmod.spear_of_the_heavens.spell_id,
    true, 0,
    function() return cast_spell.position(sdmod.spear_of_the_heavens.spell_id, target:get_position(), 0) end, 0.1)
print('DEBUG direct try_cast:', direct_ok, direct_delay)

-- Use try_cast_spell directly for cooldown verification (avoids UI/menu differences)
local sdmod = require('my_utility/spell_data')
local first_ok, first_delay = my_utility.try_cast_spell("spear_of_the_heavens", sdmod.spear_of_the_heavens.spell_id, true,
    0,
    function() return cast_spell.position(sdmod.spear_of_the_heavens.spell_id, target:get_position(), 0) end, 0.1)
if not first_ok then
    print('TEST FAIL: direct try_cast_spell failed on first attempt')
    os.exit(1)
end
-- record a cast now and verify immediate re-cast is blocked
my_utility.record_spell_cast('spear_of_the_heavens')
local second_ok = my_utility.try_cast_spell("spear_of_the_heavens", sdmod.spear_of_the_heavens.spell_id, true, 0,
    function() return cast_spell.position(sdmod.spear_of_the_heavens.spell_id, target:get_position(), 0) end, 0.1)
if second_ok then
    print('TEST FAIL: direct try_cast_spell allowed recast before internal cooldown')
    os.exit(2)
end
-- advance time beyond cooldown and try again
local last = my_utility.get_last_cast_time('spear_of_the_heavens')
_G.get_time_since_inject = function() return last + sdmod.spear_of_the_heavens.cooldown + 1 end
local third_ok = my_utility.try_cast_spell("spear_of_the_heavens", sdmod.spear_of_the_heavens.spell_id, true, 0,
    function() return cast_spell.position(sdmod.spear_of_the_heavens.spell_id, target:get_position(), 0) end, 0.1)
if not third_ok then
    print('TEST FAIL: direct try_cast_spell did not allow cast after cooldown')
    os.exit(3)
end
print('TEST PASS: spear_of_the_heavens cooldown behavior')
os.exit(0)
