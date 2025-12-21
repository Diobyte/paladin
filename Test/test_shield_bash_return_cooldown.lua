-- Test Shield Bash returns cooldown and uses CAST_DELAY

-- Minimal UI stubs
_G.tree_node = { new = function() return { push = function() return true end, pop = function() end } end }
_G.checkbox = { new = function(default) return { get = function() return default end, render = function() end } end }
_G.slider_float = { new = function(min, max, default) return { get = function() return default end, render = function() end } end }
_G.get_hash = function(x) return tostring(x) end

local TIME_NOW = 0
_G.get_time_since_inject = function() return TIME_NOW end
_G.get_player_position = function() return { x = 0, y = 0, z = 0 } end

-- Stubs
package.loaded['utility'] = { is_spell_ready = function() return true end, is_spell_affordable = function() return true end, can_cast_spell = function() return true end }
package.loaded['my_utility/my_utility'] = package.loaded['my_utility/my_utility'] or require('my_utility/my_utility')
local my_utility = require('my_utility/my_utility')
my_utility.is_spell_allowed = function(...) return true end

package.loaded['prediction'] = { is_wall_collision = function() return false end }
package.loaded['target_selector'] = { get_target_enemy = function(range) return { get_position = function() return { squared_dist_to_ignore_z = function(_, _) return 20 end } end } end }

_G.cast_spell = { target = function(target, spell_id, t) return true end }

local spells = require('spells/shield_bash')

-- Reset internal timer
if spells.set_next_time_allowed_cast then spells.set_next_time_allowed_cast(0) end

-- Execute
TIME_NOW = 0
local ok, cooldown = spells.logics()
if not ok then
    print('TEST FAIL: shield_bash.logics should succeed')
    os.exit(1)
end
if type(cooldown) ~= 'number' then
    print('TEST FAIL: shield_bash should return numeric cooldown')
    os.exit(1)
end
if math.abs(cooldown - 0.1) > 1e-6 then
    print('TEST FAIL: shield_bash cooldown expected 0.1 got', cooldown)
    os.exit(1)
end

print('TEST PASS: shield_bash returns cooldown', cooldown)

-- cleanup
package.loaded['prediction'] = nil
package.loaded['target_selector'] = nil
package.loaded['utility'] = nil
_G.cast_spell = nil
_G.get_time_since_inject = nil
os.exit(0)