local ts = require('my_utility/target_scoring')

-- vec helper like other tests
local function vec(x,y)
    return {
        x = x, y = y, z = 0,
        squared_dist_to_ignore_z = function(self, other)
            local dx = self.x - other.x; local dy = self.y - other.y; return dx*dx + dy*dy end,
        get_angle = function() return 0 end
    }
end

local function make_unit(x,y)
    return {
        get_current_health = function() return 100 end,
        get_skin_name = function() return 'Enemy' end,
        get_position = function() return vec(x,y) end,
        get_buffs = function() return {} end,
        is_enemy = function() return true end,
        is_untargetable = function() return false end,
        is_boss = function() return false end,
        is_champion = function() return false end,
        is_elite = function() return false end
    }
end

-- stub enemy counts
package.loaded['my_utility/my_utility'] = package.loaded['my_utility/my_utility'] or {}
package.loaded['my_utility/my_utility'].enemy_count_in_range = function() return 1,1,0,0,0 end

local player_pos = vec(0,0)
local cfg = { player_position = player_pos, cursor_position = vec(0,1), cursor_targeting_radius = 3, best_target_evaluation_radius = 3, cursor_targeting_angle = 60, enemy_count_threshold = 1 }

-- Two units with same basic score; closer one should be chosen
local near = make_unit(1,0)
local far = make_unit(4,0)
local best_ranged = ts.evaluate_targets({far, near}, 2, cfg)
if best_ranged ~= near then
    print('TEST FAIL: tiebreaker did not prefer closer unit')
    os.exit(1)
end
print('TEST PASS: tiebreaker prefers closer unit')

-- A tie where one unit is an infernal objective (lowercase variant). That should be preferred regardless of order
local obj = make_unit(5,0)
obj.get_skin_name = function() return 'bsk_hellseeker' end -- lowercase variant
local other = make_unit(6,0)
local best_obj = ts.evaluate_targets({other, obj}, 2, cfg)
if best_obj ~= obj then
    print('TEST FAIL: infernal objective name variant not detected')
    os.exit(1)
end
print('TEST PASS: infernal objective detection (case-insensitive) OK')

os.exit(0)
