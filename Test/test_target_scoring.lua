local ts = require('my_utility/target_scoring')
local spell_data = require('my_utility/spell_data')

-- Simple vec helper
local function vec(x, y)
    return {
        x = x,
        y = y,
        z = 0,
        squared_dist_to_ignore_z = function(self, other)
            local dx = self.x - other.x; local dy = self.y - other.y; return dx * dx + dy * dy
        end,
        get_angle = function(self, cursor_pos, player_pos)
            -- compute angle between vectors (player->cursor) and (player->self)
            local ax, ay = cursor_pos.x - player_pos.x, cursor_pos.y - player_pos.y
            local bx, by = self.x - player_pos.x, self.y - player_pos.y
            local adotb = ax * bx + ay * by
            local lena = math.sqrt(ax * ax + ay * ay)
            local lenb = math.sqrt(bx * bx + by * by)
            if lena == 0 or lenb == 0 then return 0 end
            local cosv = math.max(-1, math.min(1, adotb / (lena * lenb)))
            return math.deg(math.acos(cosv))
        end
    }
end

-- Mock units
local function make_unit(x, y, buff)
    return {
        get_current_health = function() return 10 end,
        get_skin_name = function() return 'Enemy' end,
        get_position = function() return vec(x, y) end,
        get_buffs = function() return buff and { buff } or {} end,
        is_enemy = function() return true end,
        is_untargetable = function() return false end,
        is_boss = function() return false end,
        is_champion = function() return false end,
        is_elite = function() return false end
    }
end

-- Stub my_utility.enemy_count_in_range to return 1 normal unit
package.loaded['my_utility/my_utility'] = package.loaded['my_utility/my_utility'] or {}
package.loaded['my_utility/my_utility'].enemy_count_in_range = function(range, pos) return 1, 1, 0, 0, 0 end

-- Provider buff unit
local provider_buff = { name_hash = spell_data.enemies.damage_resistance.spell_id, type = spell_data.enemies
.damage_resistance.buff_ids.provider }
local provider_unit = make_unit(1, 0, provider_buff)

-- Receiver buff unit
local receiver_buff = { name_hash = spell_data.enemies.damage_resistance.spell_id, type = spell_data.enemies
.damage_resistance.buff_ids.receiver }
local receiver_unit = make_unit(2, 0, receiver_buff)

local player_pos = vec(0, 0)
local cursor_pos = vec(0, 1)

local cfg = {
    player_position = player_pos,
    cursor_position = cursor_pos,
    cursor_targeting_radius = 3,
    best_target_evaluation_radius = 3,
    cursor_targeting_angle = 60,
    enemy_count_threshold = 1
}

local best_ranged, best_melee, best_cursor, closest_cursor, ranged_score = ts.evaluate_targets(
{ provider_unit, receiver_unit }, 2, cfg)
if best_ranged ~= provider_unit then
    print('TEST FAIL: provider should be chosen as best ranged target due to provider buff')
    os.exit(1)
end
print('TEST PASS: provider unit chosen as best ranged target')

-- Untargetable should be ignored
local untargetable_unit = make_unit(0.5, 0, nil)
untargetable_unit.is_untargetable = function() return true end
local best_ranged2 = ts.evaluate_targets({ untargetable_unit }, 2, cfg)
if best_ranged2 ~= nil then
    print('TEST FAIL: untargetable unit should be ignored')
    os.exit(1)
end
print('TEST PASS: untargetable unit ignored')

os.exit(0)
