local local_player = get_local_player();
if local_player == nil then
    return
end

local character_id = local_player:get_character_class_id();
local is_paladin = character_id == 7 or character_id == 8 or character_id == 9;
if not is_paladin then
    return
end;

-- orbwalker settings
orbwalker.set_block_movement(true);
orbwalker.set_clear_toggle(true);

local my_target_selector = require("my_utility/my_target_selector");
local my_utility = require("my_utility/my_utility");
local spell_data = require("my_utility/spell_data");
local get_spell_priority = require("spell_priority");

local current_spell_priority = get_spell_priority(0);  -- 0 for default build

local menu_elements =
{
    main_boolean                   = checkbox:new(true, get_hash(my_utility.plugin_label .. "main_boolean")),
    -- first parameter is the default state, second one the menu element's ID. The ID must be unique,
    -- not only from within the plugin but also it needs to be unique between demo menu elements and
    -- other scripts menu elements. This is why we concatenate the plugin name ("LUA_EXAMPLE_NECROMANCER")
    -- with the menu element name itself.

    main_tree                      = tree_node:new(0),

    -- trees are the menu tabs. The parameter that we pass is the depth of the node. (0 for main menu (bright red rectangle),
    -- 1 for sub-menu of depth 1 (circular red rectangle with white background) and so on)
    settings_tree                  = tree_node:new(1),
    enemy_count_threshold          = slider_int:new(1, 10, 1,
        get_hash(my_utility.plugin_label .. "enemy_count_threshold")),
    max_targeting_range            = slider_int:new(1, 30, 12, get_hash(my_utility.plugin_label .. "max_targeting_range")),
    cursor_targeting_radius        = slider_float:new(0.1, 6, 3,
        get_hash(my_utility.plugin_label .. "cursor_targeting_radius")),
    cursor_targeting_angle         = slider_int:new(20, 50, 30,
        get_hash(my_utility.plugin_label .. "cursor_targeting_angle")),
    best_target_evaluation_radius  = slider_float:new(0.1, 6, 3,
        get_hash(my_utility.plugin_label .. "best_target_evaluation_radius")),

    build_selector                = combo_box:new(0, get_hash(my_utility.plugin_label .. "build_selector")),

    enable_debug                   = checkbox:new(false, get_hash(my_utility.plugin_label .. "enable_debug")),
    debug_tree                     = tree_node:new(2),
    draw_targets                   = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_targets")),
    draw_max_range                 = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_max_range")),
    draw_melee_range               = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_melee_range")),
    draw_enemy_circles             = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_enemy_circles")),
    draw_cursor_target             = checkbox:new(false, get_hash(my_utility.plugin_label .. "draw_cursor_target")),
    targeting_refresh_interval     = slider_float:new(0.1, 1, 0.2,
        get_hash(my_utility.plugin_label .. "targeting_refresh_interval")),

    custom_enemy_weights_tree      = tree_node:new(2),
    custom_enemy_weights           = checkbox:new(false, get_hash(my_utility.plugin_label .. "custom_enemy_weights")),
    enemy_weight_normal            = slider_int:new(1, 10, 2,
        get_hash(my_utility.plugin_label .. "enemy_weight_normal")),
    enemy_weight_elite             = slider_int:new(1, 50, 10,
        get_hash(my_utility.plugin_label .. "enemy_weight_elite")),
    enemy_weight_champion          = slider_int:new(1, 50, 15,
        get_hash(my_utility.plugin_label .. "enemy_weight_champion")),
    enemy_weight_boss              = slider_int:new(1, 100, 50,
        get_hash(my_utility.plugin_label .. "enemy_weight_boss")),
    enemy_weight_damage_resistance = slider_int:new(1, 50, 25,
        get_hash(my_utility.plugin_label .. "enemy_weight_damage_resistance")),

    spells_tree                    = tree_node:new(1),
    disabled_spells_tree           = tree_node:new(1),
}

local draw_targets_description =
    "\n     Targets in sight:\n" ..
    "     Ranged Target - RED circle with line     \n" ..
    "     Melee Target - GREEN circle with line     \n" ..
    "     Closest Target - CYAN circle with line     \n\n" ..
    "     Targets out of sight (only if they are not the same as targets in sight):\n" ..
    "     Ranged Target - faded RED circle     \n" ..
    "     Melee Target - faded GREEN circle     \n" ..
    "     Closest Target - faded CYAN circle     \n\n" ..
    "     Best Target Evaluation Radius:\n" ..
    "     faded WHITE circle       \n\n"

local cursor_target_description =
    "\n     Best Cursor Target - ORANGE pentagon     \n" ..
    "     Closest Cursor Target - GREEN pentagon     \n\n"

local spells =
{
    advance = require("spells/advance"),
    evade = require("spells/evade"),
    paladin_evade = require("spells/paladin_evade"),
    arbiter_of_justice = require("spells/arbiter_of_justice"),
    blessed_hammer = require("spells/blessed_hammer"),
    blessed_shield = require("spells/blessed_shield"),
    brandish = require("spells/brandish"),
    clash = require("spells/clash"),
    condemn = require("spells/condemn"),
    consecration = require("spells/consecration"),
    defiance_aura = require("spells/defiance_aura"),
    divine_lance = require("spells/divine_lance"),
    falling_star = require("spells/falling_star"),
    fanaticism_aura = require("spells/fanaticism_aura"),
    heavens_fury = require("spells/heavens_fury"),
    holy_bolt = require("spells/holy_bolt"),
    holy_light_aura = require("spells/holy_light_aura"),
    rally = require("spells/rally"),
    shield_charge = require("spells/shield_charge"),
    spear_of_the_heavens = require("spells/spear_of_the_heavens"),
    zeal = require("spells/zeal"),
    zenith = require("spells/zenith"),
    aegis = require("spells/aegis"),
    fortress = require("spells/fortress"),
    purify = require("spells/purify"),
}

on_render_menu(function()
    if not menu_elements.main_tree:push("Paladin [Dirty] v1.0.4") then
        return;
    end;

    menu_elements.main_boolean:render("Enable Plugin", "");

    if not menu_elements.main_boolean:get() then
        -- plugin not enabled, stop rendering menu elements
        menu_elements.main_tree:pop();
        return;
    end;

    if menu_elements.settings_tree:push("Settings") then
        menu_elements.enemy_count_threshold:render("Minimum Enemy Count",
            "       Minimum number of enemies in Enemy Evaluation Radius to consider them for targeting")
        menu_elements.targeting_refresh_interval:render("Targeting Refresh Interval",
            "       Time between target checks in seconds       ", 1)
        menu_elements.max_targeting_range:render("Max Targeting Range",
            "       Maximum range for targeting       ")
        menu_elements.cursor_targeting_radius:render("Cursor Targeting Radius",
            "       Area size for selecting target around the cursor       ", 1)
        menu_elements.cursor_targeting_angle:render("Cursor Targeting Angle",
            "       Maximum angle between cursor and target to cast targetted spells       ")
        menu_elements.best_target_evaluation_radius:render("Enemy Evaluation Radius",
            "       Area size around an enemy to evaluate if it's the best target       \n" ..
            "       If you use huge aoe spells, you should increase this value       \n" ..
            "       Size is displayed with debug/display targets with faded white circles       ", 1)

        menu_elements.build_selector:render("Build Selector", {"Default", "Judgement Nuke Paladin", "Blessed Hammer (Hammerkuna)", "Arbiter Paladin", "Blessed Shield (Captain America)", "Shield Bash Valkyrie", "Holy Avenger Wing Strikes", "Evade Hammerdin", "Arbiter Evade", "Heaven's Fury Spam", "Spear of the Heavens", "Condemn Spam", "Zenith Aegis Tank"}, "Select a build to optimize spell priorities and timings for max DPS")

        -- Update spell priority based on selected build
        current_spell_priority = get_spell_priority(menu_elements.build_selector:get())

        menu_elements.custom_enemy_weights:render("Custom Enemy Weights",
            "Enable custom enemy weights for determining best targets within Enemy Evaluation Radius")
        if menu_elements.custom_enemy_weights:get() then
            if menu_elements.custom_enemy_weights_tree:push("Custom Enemy Weights") then
                menu_elements.enemy_weight_normal:render("Normal Enemy Weight",
                    "Weighing score for normal enemies - default is 2")
                menu_elements.enemy_weight_elite:render("Elite Enemy Weight",
                    "Weighing score for elite enemies - default is 10")
                menu_elements.enemy_weight_champion:render("Champion Enemy Weight",
                    "Weighing score for champion enemies - default is 15")
                menu_elements.enemy_weight_boss:render("Boss Enemy Weight",
                    "Weighing score for boss enemies - default is 50")
                menu_elements.enemy_weight_damage_resistance:render("Damage Resistance Aura Enemy Weight",
                    "Weighing score for enemies with damage resistance aura - default is 25")
                menu_elements.custom_enemy_weights_tree:pop()
            end
        end

        menu_elements.enable_debug:render("Enable Debug", "")
        if menu_elements.enable_debug:get() then
            if menu_elements.debug_tree:push("Debug") then
                menu_elements.draw_targets:render("Display Targets", draw_targets_description)
                menu_elements.draw_max_range:render("Display Max Range",
                    "Draw max range circle")
                menu_elements.draw_melee_range:render("Display Melee Range",
                    "Draw melee range circle")
                menu_elements.draw_enemy_circles:render("Display Enemy Circles",
                    "Draw enemy circles")
                menu_elements.draw_cursor_target:render("Display Cursor Target", cursor_target_description)
                menu_elements.debug_tree:pop()
            end
        end

        menu_elements.settings_tree:pop()
    end

    local equipped_spells = get_equipped_spell_ids()

    -- Create a lookup table for equipped spells
    local equipped_lookup = {}
    for _, spell_id in ipairs(equipped_spells) do
        -- Check each spell in spell_data to find matching spell_id
        for spell_name, data in pairs(spell_data) do
            if data.spell_id == spell_id then
                equipped_lookup[spell_name] = true
                break
            end
        end
    end

    if menu_elements.spells_tree:push("Equipped Spells") then
        -- Display spells in priority order, but only if they're equipped
        for _, spell_name in ipairs(current_spell_priority) do
            if equipped_lookup[spell_name] or spell_name == "evade" then
                local spell = spells[spell_name]
                if spell then
                    spell.menu()
                end
            end
        end
        menu_elements.spells_tree:pop()
    end

    if menu_elements.disabled_spells_tree:push("Inactive Spells") then
        for _, spell_name in ipairs(current_spell_priority) do
            local spell = spells[spell_name]
            if spell and spell_name ~= "evade" and (not equipped_lookup[spell_name] or not spell.menu_elements.main_boolean:get()) then
                spell.menu()
            end
        end
        menu_elements.disabled_spells_tree:pop()
    end

    menu_elements.main_tree:pop();
end)

-- Targets
local best_ranged_target = nil
local best_ranged_target_visible = nil
local best_melee_target = nil
local best_melee_target_visible = nil
local closest_target = nil
local closest_target_visible = nil
local best_cursor_target = nil
local closest_cursor_target = nil
local closest_cursor_target_angle = 0
-- Targetting scores
local ranged_max_score = 0
local ranged_max_score_visible = 0
local melee_max_score = 0
local melee_max_score_visible = 0
local cursor_max_score = 0

-- Targetting settings
local max_targeting_range = menu_elements.max_targeting_range:get()
local collision_table = { true, 1 } -- collision width
local floor_table = { true, 5.0 }   -- floor height
local angle_table = { false, 90.0 } -- max angle

-- Cache for heavy function results
local next_target_update_time = 0.0 -- Time of next target evaluation
local next_cast_time = 0.0          -- Time of next possible cast
local targeting_refresh_interval = menu_elements.targeting_refresh_interval:get()

-- Default enemy weights for different enemy types
local normal_monster_value = 2
local elite_value = 10
local champion_value = 15
local boss_value = 50
local damage_resistance_value = 25

local target_selector_data_all = nil

local function evaluate_targets(target_list, melee_range)
    local best_ranged_target = nil
    local best_melee_target = nil
    local best_cursor_target = nil
    local closest_cursor_target = nil
    local closest_cursor_target_angle = 0

    local ranged_max_score = 0
    local melee_max_score = 0
    local cursor_max_score = 0

    local melee_range_sqr = melee_range * melee_range
    local player_position = get_player_position()
    local cursor_position = get_cursor_position()
    local cursor_targeting_radius = menu_elements.cursor_targeting_radius:get()
    local cursor_targeting_radius_sqr = cursor_targeting_radius * cursor_targeting_radius
    local best_target_evaluation_radius = menu_elements.best_target_evaluation_radius:get()
    local cursor_targeting_angle = menu_elements.cursor_targeting_angle:get()
    local enemy_count_threshold = menu_elements.enemy_count_threshold:get()
    local closest_cursor_distance_sqr = math.huge

    for _, unit in ipairs(target_list) do
        local unit_health = unit:get_current_health()
        local unit_name = unit:get_skin_name()
        local unit_position = unit:get_position()
        local distance_sqr = unit_position:squared_dist_to_ignore_z(player_position)
        local cursor_distance_sqr = unit_position:squared_dist_to_ignore_z(cursor_position)
        local buffs = unit:get_buffs()

        -- get enemy count in range of enemy unit
        local all_units_count, normal_units_count, elite_units_count, champion_units_count, boss_units_count = my_utility
            .enemy_count_in_range(best_target_evaluation_radius, unit_position)

        -- if enemy count is less than enemy count threshold and unit is not elite, champion or boss, skip this unit
        if all_units_count < enemy_count_threshold and not (unit:is_elite() or unit:is_champion() or unit:is_boss()) then
            goto continue
        end

        local total_score = normal_units_count * normal_monster_value
        if boss_units_count > 0 then
            total_score = total_score + boss_value * boss_units_count
        elseif champion_units_count > 0 then
            total_score = total_score + champion_value * champion_units_count
        elseif elite_units_count > 0 then
            total_score = total_score + elite_value * elite_units_count
        end

        -- Check if unit has damage resistance buff
        for _, buff in ipairs(buffs) do
            if buff.name_hash == spell_data.enemies.damage_resistance.spell_id then
                -- if the enemy is the provider of the damage resistance aura
                if buff.type == spell_data.enemies.damage_resistance.buff_ids.provider then
                    total_score = total_score + damage_resistance_value
                    break
                else -- otherwise the enemy is the receiver of the damage resistance aura
                    total_score = total_score - damage_resistance_value
                    break
                end
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
            local angle_to_cursor = unit_position:get_angle(cursor_position, player_position)
            if angle_to_cursor <= cursor_targeting_angle then
                -- in cursor radius
                if cursor_distance_sqr <= cursor_targeting_radius_sqr then
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

        ::continue::
    end

    return best_ranged_target, best_melee_target, best_cursor_target, closest_cursor_target, ranged_max_score,
        melee_max_score, cursor_max_score, closest_cursor_target_angle
end

local function use_ability(spell_name, delay_after_cast)
    local spell = spells[spell_name]
    if not (spell and spell.menu_elements.main_boolean:get()) then
        return false
    end

    local target_unit = nil
    if spell.menu_elements.targeting_mode then
        local targeting_mode = spell.menu_elements.targeting_mode:get()
        
        -- Check for specific targeting maps in the spell module
        if spell.targeting_type == "melee" then
            -- Map melee modes to global indices
            local map = {
                [0] = 2, -- Melee Target
                [1] = 3, -- Melee Target (in sight)
                [2] = 4, -- Closest Target
                [3] = 5, -- Closest Target (in sight)
                [4] = 6, -- Best Cursor Target
                [5] = 7  -- Closest Cursor Target
            }
            targeting_mode = map[targeting_mode] or 2 -- Default to Melee Target
        elseif spell.targeting_type == "ranged" then
            -- Map ranged modes to global indices
            local map = {
                [0] = 0, -- Ranged Target
                [1] = 1, -- Ranged Target (in sight)
                [2] = 4, -- Closest Target
                [3] = 5, -- Closest Target (in sight)
                [4] = 6, -- Best Cursor Target
                [5] = 7  -- Closest Cursor Target
            }
            targeting_mode = map[targeting_mode] or 0 -- Default to Ranged Target
        end

        target_unit = ({
            [0] = best_ranged_target,
            [1] = best_ranged_target_visible,
            [2] = best_melee_target,
            [3] = best_melee_target_visible,
            [4] = closest_target,
            [5] = closest_target_visible,
            [6] = best_cursor_target,
            [7] = closest_cursor_target
        })[targeting_mode]
    end

    --if target_unit is nil, it means the spell is not targetted and we use the default logic without target
    if (target_unit and spell.logics(target_unit)) or (not target_unit and spell.logics()) then
        next_cast_time = get_time_since_inject() + delay_after_cast
        my_utility.record_spell_cast(spell_name)
        return true
    end

    return false
end

-- on_update callback
on_update(function()
    local current_time = get_time_since_inject()
    local local_player = get_local_player()
    if not local_player or menu_elements.main_boolean:get() == false or current_time < next_cast_time then
        return
    end

    if not my_utility.is_action_allowed() then
        return;
    end

    targeting_refresh_interval = menu_elements.targeting_refresh_interval:get()
    -- Only update targets if targeting_refresh_interval has expired
    if current_time >= next_target_update_time then
        local player_position = get_player_position()
        max_targeting_range = menu_elements.max_targeting_range:get()

        local entity_list_visible, entity_list = my_target_selector.get_target_list(
            player_position,
            max_targeting_range,
            collision_table,
            floor_table,
            angle_table)

        target_selector_data_all = my_target_selector.get_target_selector_data(
            player_position,
            entity_list)

        local target_selector_data_visible = my_target_selector.get_target_selector_data(
            player_position,
            entity_list_visible)

        if not target_selector_data_all or not target_selector_data_all.is_valid then
            return
        end

        -- Reset targets
        best_ranged_target = nil
        best_melee_target = nil
        closest_target = nil
        best_ranged_target_visible = nil
        best_melee_target_visible = nil
        closest_target_visible = nil
        best_cursor_target = nil
        closest_cursor_target = nil
        closest_cursor_target_angle = 0
        local melee_range = my_utility.get_melee_range()

        -- Update enemy weights, use custom weights if enabled
        if menu_elements.custom_enemy_weights:get() then
            normal_monster_value = menu_elements.enemy_weight_normal:get()
            elite_value = menu_elements.enemy_weight_elite:get()
            champion_value = menu_elements.enemy_weight_champion:get()
            boss_value = menu_elements.enemy_weight_boss:get()
            damage_resistance_value = menu_elements.enemy_weight_damage_resistance:get()
        else
            normal_monster_value = 2
            elite_value = 10
            champion_value = 15
            boss_value = 50
            damage_resistance_value = 25
        end

        -- Check all targets within max range
        if target_selector_data_all and target_selector_data_all.is_valid then
            best_ranged_target, best_melee_target, best_cursor_target, closest_cursor_target, ranged_max_score,
            melee_max_score, cursor_max_score, closest_cursor_target_angle = evaluate_targets(
                target_selector_data_all.list,
                melee_range)
            closest_target = target_selector_data_all.closest_unit
        end


        -- Check visible targets within max range
        if target_selector_data_visible and target_selector_data_visible.is_valid then
            best_ranged_target_visible, best_melee_target_visible, _, _,
            ranged_max_score_visible, melee_max_score_visible, _ = evaluate_targets(
                target_selector_data_visible.list,
                melee_range)
            closest_target_visible = target_selector_data_visible.closest_unit
        end

        -- Update next target update time
        next_target_update_time = current_time + targeting_refresh_interval
    end

    -- Ability usage - uses spell_priority to determine the order of spells
    for _, spell_name in ipairs(current_spell_priority) do
        local spell = spells[spell_name]
        if spell then
            if use_ability(spell_name, my_utility.spell_delays.regular_cast) then
                return
            end
        end
    end
end)

-- Debug
local font_size = 16
local y_offset = font_size + 2
local visible_text = 255
local visible_alpha = 180
local alpha = 100
local target_evaluation_radius_alpha = 50
on_render(function()
    if menu_elements.main_boolean:get() == false or not menu_elements.enable_debug:get() then
        return;
    end;

    local local_player = get_local_player();
    if not local_player then
        return;
    end

    local player_position = local_player:get_position();
    local player_screen_position = graphics.w2s(player_position);
    if player_screen_position:is_zero() then
        return;
    end

    -- Draw max range
    max_targeting_range = menu_elements.max_targeting_range:get()
    if menu_elements.draw_max_range:get() then
        graphics.circle_3d(player_position, max_targeting_range, color_white(85), 2.5, 144)
    end

    -- Draw melee range
    if menu_elements.draw_melee_range:get() then
        local melee_range = my_utility.get_melee_range()
        graphics.circle_3d(player_position, melee_range, color_white(85), 2.5, 144)
    end

    -- Draw enemy circles
    if menu_elements.draw_enemy_circles:get() then
        local enemies = actors_manager.get_enemy_npcs()

        for i, obj in ipairs(enemies) do
            local position = obj:get_position();
            graphics.circle_3d(position, 1, color_white(100));

            local future_position = prediction.get_future_unit_position(obj, 0.4);
            graphics.circle_3d(future_position, 0.25, color_yellow(100));
        end;
    end

    if menu_elements.draw_cursor_target:get() then
        local cursor_position = get_cursor_position()
        local cursor_targeting_radius = menu_elements.cursor_targeting_radius:get()

        -- Draw cursor radius
        graphics.circle_3d(cursor_position, cursor_targeting_radius, color_white(target_evaluation_radius_alpha), 1);
    end

    -- Only draw targets if we have valid target selector data
    if not target_selector_data_all or not target_selector_data_all.is_valid then
        return
    end

    local best_target_evaluation_radius = menu_elements.best_target_evaluation_radius:get()

    -- Draw targets
    if menu_elements.draw_targets:get() then
        -- Draw visible ranged target
        if best_ranged_target_visible and best_ranged_target_visible:is_enemy() then
            local best_ranged_target_visible_position = best_ranged_target_visible:get_position();
            local best_ranged_target_visible_position_2d = graphics.w2s(best_ranged_target_visible_position);
            graphics.line(best_ranged_target_visible_position_2d, player_screen_position, color_red(visible_alpha),
                2.5)
            graphics.circle_3d(best_ranged_target_visible_position, 0.80, color_red(visible_alpha), 2.0);
            graphics.circle_3d(best_ranged_target_visible_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(best_ranged_target_visible_position_2d.x,
                best_ranged_target_visible_position_2d.y - y_offset)
            graphics.text_2d("RANGED_VISIBLE - Score:" .. ranged_max_score_visible, text_position, font_size,
                color_red(visible_text))
        end

        -- Draw ranged target if it's not the same as the visible ranged target
        if best_ranged_target_visible ~= best_ranged_target and best_ranged_target and best_ranged_target:is_enemy() then
            local best_ranged_target_position = best_ranged_target:get_position();
            local best_ranged_target_position_2d = graphics.w2s(best_ranged_target_position);
            graphics.circle_3d(best_ranged_target_position, 0.80, color_red_pale(alpha), 2.0);
            graphics.circle_3d(best_ranged_target_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(best_ranged_target_position_2d.x,
                best_ranged_target_position_2d.y - y_offset)
            graphics.text_2d("RANGED - Score:" .. ranged_max_score, text_position, font_size, color_red_pale(alpha))
        end

        -- Draw visible melee target
        if best_melee_target_visible and best_melee_target_visible:is_enemy() then
            local best_melee_target_visible_position = best_melee_target_visible:get_position();
            local best_melee_target_visible_position_2d = graphics.w2s(best_melee_target_visible_position);
            graphics.line(best_melee_target_visible_position_2d, player_screen_position, color_green(visible_alpha),
                2.5)
            graphics.circle_3d(best_melee_target_visible_position, 0.70, color_green(visible_alpha), 2.0);
            graphics.circle_3d(best_melee_target_visible_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(best_melee_target_visible_position_2d.x,
                best_melee_target_visible_position_2d.y)
            graphics.text_2d("MELEE_VISIBLE - Score:" .. melee_max_score_visible, text_position, font_size,
                color_green(visible_text))
        end

        -- Draw melee target if it's not the same as the visible melee target
        if best_melee_target_visible ~= best_melee_target and best_melee_target and best_melee_target:is_enemy() then
            local best_melee_target_position = best_melee_target:get_position();
            local best_melee_target_position_2d = graphics.w2s(best_melee_target_position);
            graphics.circle_3d(best_melee_target_position, 0.70, color_green_pale(alpha), 2.0);
            graphics.circle_3d(best_melee_target_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(best_melee_target_position_2d.x, best_melee_target_position_2d.y)
            graphics.text_2d("MELEE - Score:" .. melee_max_score, text_position, font_size, color_green_pale(alpha))
        end

        -- Draw visible closest target
        if closest_target_visible and closest_target_visible:is_enemy() then
            local closest_target_visible_position = closest_target_visible:get_position();
            local closest_target_visible_position_2d = graphics.w2s(closest_target_visible_position);
            graphics.line(closest_target_visible_position_2d, player_screen_position, color_cyan(visible_alpha), 2.5)
            graphics.circle_3d(closest_target_visible_position, 0.60, color_cyan(visible_alpha), 2.0);
            graphics.circle_3d(closest_target_visible_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(closest_target_visible_position_2d.x,
                closest_target_visible_position_2d.y + y_offset)
            graphics.text_2d("CLOSEST_VISIBLE", text_position, font_size, color_cyan(visible_text))
        end

        -- Draw closest target if it's not the same as the visible closest target
        if closest_target_visible ~= closest_target and closest_target and closest_target:is_enemy() then
            local closest_target_position = closest_target:get_position();
            local closest_target_position_2d = graphics.w2s(closest_target_position);
            graphics.circle_3d(closest_target_position, 0.60, color_cyan_pale(alpha), 2.0);
            graphics.circle_3d(closest_target_position, best_target_evaluation_radius,
                color_white(target_evaluation_radius_alpha), 1);
            local text_position = vec2:new(closest_target_position_2d.x, closest_target_position_2d.y + y_offset)
            graphics.text_2d("CLOSEST", text_position, font_size, color_cyan_pale(alpha))
        end
    end

    if menu_elements.draw_cursor_target:get() then
        -- Draw best cursor target
        if best_cursor_target and best_cursor_target:is_enemy() then
            local best_cursor_target_position = best_cursor_target:get_position();
            local best_cursor_target_position_2d = graphics.w2s(best_cursor_target_position);
            graphics.circle_3d(best_cursor_target_position, 0.60, color_orange_red(255), 2.0, 5);
            graphics.text_2d("BEST_CURSOR_TARGET - Score:" .. cursor_max_score, best_cursor_target_position_2d, font_size,
                color_orange_red(255))
        end

        -- Draw closest cursor target
        if closest_cursor_target and closest_cursor_target:is_enemy() then
            local closest_cursor_target_position = closest_cursor_target:get_position();
            local closest_cursor_target_position_2d = graphics.w2s(closest_cursor_target_position);
            graphics.circle_3d(closest_cursor_target_position, 0.40, color_green_pastel(255), 2.0, 5);
            local text_position = vec2:new(closest_cursor_target_position_2d.x,
                closest_cursor_target_position_2d.y + y_offset)
            graphics.text_2d("CLOSEST_CURSOR_TARGET - Angle:" .. string.format("%.1f", closest_cursor_target_angle),
                text_position, font_size,
                color_green_pastel(255))
        end
    end
end);

console.print("Lua Plugin - Paladin Dirty - Version 1.1.3")
