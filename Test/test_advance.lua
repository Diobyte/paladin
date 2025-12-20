-- Test Advance cooldown behavior
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.combo_box = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end
_G.get_player_position = function() return { x = 0, y = 0, z = 0 } end
_G.get_cursor_position = function() return { x = 1, y = 0, z = 0, squared_dist_to_ignore_z = function(self, other) return 1 end } end
_G.get_local_player = function() return { get_primary_resource_current = function() return 0 end, get_primary_resource_max = function() return 1 end } end

local spells = require('spells/advance')
local my_utility = require('my_utility/my_utility')
my_utility.is_spell_allowed = function(...) return true end
my_utility.is_in_range = function(target, range)
    local pos = target and target:get_position() or { x = 0, y = 0, z = 0 }
    local p = get_player_position()
    local dx = pos.x - p.x; local dy = pos.y - p.y
    return (dx * dx + dy * dy) < (range * range)
end
my_utility.is_high_priority_target = function() return false end

local target = { get_position = function() return { x = 5, y = 0, z = 0 } end, is_elite = function() return false end }
_G.cast_spell = { position = function(spell_id, pos, t) return true end }

if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

-- Combat-mode with target
spells.menu_elements.mobility_only = { get = function() return false end }
spells.menu_elements.elites_only = { get = function() return false end }
spells.menu_elements.force_priority = { get = function() return true end }

TIME_NOW = 0
if not spells.logics(target) then
    print('TEST FAIL: advance first cast failed')
    os.exit(1)
end
TIME_NOW = 0.05
if spells.logics(target) then
    print('TEST FAIL: advance allowed early recast')
    os.exit(2)
end
TIME_NOW = 0.2
if not spells.logics(target) then
    print('TEST FAIL: advance did not cast after delay')
    os.exit(3)
end

print('TEST PASS: advance cooldown behavior')
os.exit(0)
