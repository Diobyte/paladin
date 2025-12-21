-- Test Clash cooldown behavior
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.combo_box = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end
_G.get_player_position = function() return { x = 0, y = 0, z = 0 } end

local spells = require('spells/clash')
local my_utility = require('my_utility/my_utility')
my_utility.is_spell_allowed = function(...) return true end
my_utility.has_shield = function() return true end
my_utility.is_in_range = function(target, range)
    local pos = target:get_position()
    local p = get_player_position()
    local dx = pos.x - p.x; local dy = pos.y - p.y
    return (dx * dx + dy * dy) < (range * range)
end

local target = { get_position = function() return { x = 3, y = 0, z = 0 } end, is_elite = function() return false end }
_G.cast_spell = { target = function(target, id, t, b) return true end }
-- Ensure menu elements permissive
spells.menu_elements.main_boolean = { get = function() return true end }
spells.menu_elements.min_target_range = { get = function() return 0 end }
spells.menu_elements.elites_only = { get = function() return false end }

if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

-- Use try_cast_spell directly
local sdmod = require('my_utility/spell_data')
local ok, delay = my_utility.try_cast_spell('clash', sdmod.clash.spell_id, true, 0,
    function() return cast_spell.target(target, sdmod.clash.spell_id, 0, false) end, 0.1)
if not ok then
    print('TEST FAIL: clash direct try_cast failed')
    os.exit(1)
end
print('TEST PASS: clash direct try_cast success')
os.exit(0)
