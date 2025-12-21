local ts = require('my_utility/target_scoring')

local function vec(x,y)
    return { x=x, y=y, z=0, squared_dist_to_ignore_z = function(self, other) local dx=self.x-other.x; local dy=self.y-other.y; return dx*dx+dy*dy end, get_angle = function() return 0 end }
end
local function make_unit(x,y)
    return { get_current_health=function() return 100 end, get_skin_name=function() return 'Enemy' end, get_position=function() return vec(x,y) end, get_buffs=function() return {} end, is_enemy=function() return true end, is_untargetable=function() return false end, is_boss=function() return false end, is_champion=function() return false end, is_elite=function() return false end }
end

-- stub enemy counts that reflect whether the source position belongs to an elite or normal unit
package.loaded['my_utility/my_utility'] = package.loaded['my_utility/my_utility'] or {}
package.loaded['my_utility/my_utility'].enemy_count_in_range = function(range, pos)
    -- if the source position x is 2 (our elite), return elite count
    if pos and pos.x == 2 then
        return 1, 0, 1, 0, 0 -- all, normal, elite, champion, boss
    end
    return 1, 1, 0, 0, 0
end

local player_pos = vec(0,0)
local cfg_default = { player_position = player_pos, cursor_position = vec(0,1), cursor_targeting_radius = 3, best_target_evaluation_radius = 3, cursor_targeting_angle = 60, enemy_count_threshold = 1 }

-- create normal and elite
local normal = make_unit(1,0)
local elite = make_unit(2,0)
elite.is_elite = function() return true end

-- default weights should prefer elite
local best_default = ts.evaluate_targets({normal, elite}, 2, cfg_default)
if best_default ~= elite then
    print('TEST FAIL: default weights should prefer elite')
    os.exit(1)
end
print('TEST PASS: default weight prefers elite')

-- custom weights: make normal much more valuable
local cfg_custom = { player_position = player_pos, cursor_position = vec(0,1), cursor_targeting_radius = 3, best_target_evaluation_radius = 3, cursor_targeting_angle = 60, enemy_count_threshold = 1, normal_monster_value = 100, elite_value = 1 }
local best_custom = ts.evaluate_targets({normal, elite}, 2, cfg_custom)
if best_custom ~= normal then
    print('TEST FAIL: custom weights did not prefer normal')
    os.exit(1)
end
print('TEST PASS: custom enemy weight sliders affect selection')

os.exit(0)
