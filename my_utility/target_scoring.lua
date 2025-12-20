local my_utility = require('my_utility/my_utility')
local spell_data = require('my_utility/spell_data')

local function evaluate_targets(target_list, melee_range, config)
    config = config or {}
    local player_position = config.player_position or get_player_position()
    local cursor_position = config.cursor_position or get_cursor_position()
    local cursor_targeting_radius = config.cursor_targeting_radius or 3
    local cursor_targeting_radius_sqr = cursor_targeting_radius * cursor_targeting_radius
    local best_target_evaluation_radius = config.best_target_evaluation_radius or 3
    local cursor_targeting_angle = config.cursor_targeting_angle or 30
    local enemy_count_threshold = config.enemy_count_threshold or 1

    local best_ranged_target = nil
    local best_melee_target = nil
    local best_cursor_target = nil
    local closest_cursor_target = nil
    local closest_cursor_target_angle = 0

    local ranged_max_score = 0
    local melee_max_score = 0
    local cursor_max_score = 0

    local melee_range_sqr = melee_range * melee_range
    local closest_cursor_distance_sqr = math.huge

    for _, unit in ipairs(target_list) do
        -- Preliminary checks: unit must exist and not be untargetable/immune; must be enemy if available
        if not unit then break end
        if (type(unit.is_enemy) == 'function' and not unit:is_enemy()) or (type(unit.is_untargetable) == 'function' and unit:is_untargetable()) or (type(unit.is_immune) == 'function' and unit:is_immune()) then
            -- ignore invalid unit
        else
            local unit_health = unit.get_current_health and unit:get_current_health() or 0
            local unit_name = unit.get_skin_name and unit:get_skin_name() or ''
            local unit_position = unit.get_position and unit:get_position() or player_position
            local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position)
            local cursor_distance_sqr = unit_position:squared_dist_to_ignore_z(cursor_position)
            local buffs = unit.get_buffs and unit:get_buffs() or {}

            -- get enemy count in range of enemy unit
            local all_units_count, normal_units_count, elite_units_count, champion_units_count, boss_units_count =
                my_utility
                .enemy_count_in_range(best_target_evaluation_radius, unit_position)

            -- if enemy count is less than threshold and unit is not elite/champion/boss skip
            if not (all_units_count < enemy_count_threshold and not (unit.is_elite and unit:is_elite() or unit.is_champion and unit:is_champion() or unit.is_boss and unit:is_boss())) then
                local total_score = (normal_units_count or 0) * (config.normal_monster_value or 2)
                total_score = total_score + ((config.boss_value or 50) * (boss_units_count or 0))
                total_score = total_score + ((config.champion_value or 15) * (champion_units_count or 0))
                total_score = total_score + ((config.elite_value or 10) * (elite_units_count or 0))

                -- Check for damage resistance aura buffs
                for _, buff in ipairs(buffs) do
                    if buff and buff.name_hash == spell_data.enemies.damage_resistance.spell_id then
                        -- if the enemy is the provider of the damage resistance aura
                        if buff.type == spell_data.enemies.damage_resistance.buff_ids.provider then
                            total_score = total_score + (config.damage_resistance_value or 25)
                        else
                            total_score = total_score - (config.damage_resistance_value or 25)
                        end
                        break
                    end
                end

                -- Check if unit is an infernal horde objective
                for _, objective_name in ipairs(my_utility.horde_objectives) do
                    if unit_name:match(objective_name) and unit_health > 1 then
                        total_score = total_score + 1000
                        break
                    end
                end

                -- in max range
                if total_score > ranged_max_score then
                    ranged_max_score = total_score
                    best_ranged_target = unit
                end

                -- in melee range
                if distance_sqr < melee_range_sqr and total_score > melee_max_score then
                    melee_max_score = total_score
                    best_melee_target = unit
                end

                -- in cursor angle
                if cursor_distance_sqr <= cursor_targeting_radius_sqr then
                    local angle_to_cursor = unit_position.get_angle and
                    unit_position:get_angle(cursor_position, player_position) or 0
                    if angle_to_cursor <= cursor_targeting_angle then
                        if total_score > cursor_max_score then
                            cursor_max_score = total_score
                            best_cursor_target = unit
                        end

                        if cursor_distance_sqr < closest_cursor_distance_sqr then
                            closest_cursor_distance_sqr = cursor_distance_sqr
                            closest_cursor_target = unit
                            closest_cursor_target_angle = angle_to_cursor
                        end
                    end
                end
            end
        end
    end

    return best_ranged_target, best_melee_target, best_cursor_target, closest_cursor_target, ranged_max_score,
        melee_max_score, cursor_max_score, closest_cursor_target_angle
end

return {
    evaluate_targets = evaluate_targets
}
