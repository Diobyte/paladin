-- Test Blessed Hammer cooldown behavior
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.combo_box = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.slider_int = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end
_G.get_player_position = function() return { x = 0, y = 0, z = 0 } end

local spells = require('spells/blessed_hammer')
local my_utility = require('my_utility/my_utility')
-- Provide permissive utility and orbwalker stubs so is_spell_allowed runs its checks
local util_stub = { is_spell_ready = function() return true end, is_spell_affordable = function() return true end, can_cast_spell = function() return true end }
package.loaded['utility'] = util_stub
_G.utility = util_stub
local orb_stub = { get_orb_mode = function() return 1 end }
package.loaded['orbwalker'] = orb_stub
_G.orbwalker = orb_stub
_G.orb_mode = { none = 0, pvp = 1, clear = 2 }
-- Auto-play stubs
local auto_play_stub = { is_active = function() return false end, get_objective = function() return 0 end }
package.loaded['auto_play'] = auto_play_stub
_G.auto_play = auto_play_stub
local objective_stub = { fight = 1 }
package.loaded['objective'] = objective_stub
_G.objective = objective_stub
-- Minimal get_local_player used by is_spell_allowed
_G.get_local_player = function() return { get_buffs = function() return {} end, get_active_spell_id = function() return 0 end, get_equipped_items = function() return {} end, get_current_health = function() return 100 end, get_max_health = function() return 100 end, get_position = function() return { x = 0, y = 0, z = 0 } end } end
-- Evade stub used by is_spell_allowed
local evade_stub = { is_dangerous_position = function() return false end }
package.loaded['evade'] = evade_stub
_G.evade = evade_stub

-- Enable internal debug prints to surface try_cast decisions
my_utility.set_debug_enabled(true)
_G.console = { print = function(...) print(...) end }
my_utility.is_in_range = function(target, range)
    local pos = target:get_position()
    local p = get_player_position()
    local dx = pos.x - p.x; local dy = pos.y - p.y
    return (dx * dx + dy * dy) < (range * range)
end

local target = { get_position = function() return { x = 5, y = 0, z = 0 } end, is_elite = function() return false end }
_G.cast_spell = { self = function(spell_id, t) return true end }
-- Force min target range lower than target distance for this test
spells.menu_elements.min_target_range = { get = function() return 0 end }
-- Ensure main boolean returns true
spells.menu_elements.main_boolean = { get = function() return true end }
-- Ensure elites_only returns false so non-elites are valid targets
spells.menu_elements.elites_only = { get = function() return false end }

if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

-- Debug direct try_cast_spell and conditions
local sdmod = require('my_utility/spell_data')
local direct_ok, direct_delay = my_utility.try_cast_spell("blessed_hammer", sdmod.blessed_hammer.spell_id, true, 0,
    function() return cast_spell.self(sdmod.blessed_hammer.spell_id, 0) end, 0.1)
print('DEBUG direct try_cast:', direct_ok, direct_delay)
print('DEBUG menu_boolean=', spells.menu_elements.main_boolean:get(), 'min_target_range=',
    spells.menu_elements.min_target_range:get())
local is_in_min_range = my_utility.is_in_range(target, spells.menu_elements.min_target_range:get())
print('DEBUG in_range=', my_utility.is_in_range(target, 8.0), 'in_min_range=', is_in_min_range)

-- Additional debug: check my_utility.is_spell_allowed check used by spells.logics
local sdmod = require('my_utility/spell_data')
local menu_bool = spells.menu_elements.main_boolean:get()
local logic_allowed = (type(my_utility.is_spell_allowed) == 'function') and
    my_utility.is_spell_allowed(menu_bool, 0, sdmod.blessed_hammer.spell_id) or false
print('DEBUG menu_bool=', menu_bool, 'type=', type(menu_bool), 'logic_allowed=', logic_allowed)
print('DEBUG utility global=', tostring(utility), 'package.utility=', tostring(package.loaded['utility']))

TIME_NOW = 0
if not spells.logics(target) then
    print('TEST FAIL: blessed_hammer first cast failed')
    os.exit(1)
end
TIME_NOW = 0.05
if spells.logics(target) then
    print('TEST FAIL: blessed_hammer allowed early recast')
    os.exit(2)
end
local last_cast = my_utility.get_last_cast_time('blessed_hammer')
TIME_NOW = last_cast + 1.01
if not spells.logics(target) then
    print('TEST FAIL: blessed_hammer did not cast after delay')
    os.exit(3)
end

print('TEST PASS: blessed_hammer cooldown behavior')
os.exit(0)
