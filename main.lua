-- NOTE:
-- Do not `return` at file-load time. If the player/orbwalker isn't ready yet,
-- returning here prevents `on_render_menu` from being registered (GUI won't show).
-- Gate class-specific logic inside callbacks instead.

local orbwalker_initialized = false;

local function try_init_orbwalker()
    if orbwalker_initialized then
        return;
    end

    if type(orbwalker) == "table" and type(orbwalker.set_block_movement) == "function" and
        type(orbwalker.set_clear_toggle) == "function" then
        orbwalker.set_block_movement(true);
        orbwalker.set_clear_toggle(true);
        orbwalker_initialized = true;
    end
end

-- Add cast_end_time mechanism to prevent spell overlap (from reference repos)
local cast_end_time = 0.0

local my_target_selector = require("my_utility/my_target_selector");
local my_utility = require("my_utility/my_utility");
local spell_data = require("my_utility/spell_data");
local target_scoring = require("my_utility/target_scoring");
local logger = require("my_utility/logger");
local get_spell_priority = require("spell_priority");
local menu = require("menu")

-- Equipped spells lookup
local equipped_lookup = {}

-- Fast lookup: spell_id -> spell_name (built once)
local spell_id_to_name = {}
for spell_name, data in pairs(spell_data) do
    if type(data) == "table" and data.spell_id ~= nil then
        spell_id_to_name[data.spell_id] = spell_name
    end
end

local next_equipped_refresh_time = 0.0
local function refresh_equipped_lookup()
    equipped_lookup = {}

    local local_player = get_local_player()
    if not local_player then
        return
    end

    local player_spells = local_player:get_spells()
    if not player_spells then
        return
    end

    for _, s in ipairs(player_spells) do
        if s and s.is_equipped and s.spell_id then
            local spell_name = spell_id_to_name[s.spell_id]
            if spell_name then
                equipped_lookup[spell_name] = true
            end
        end
    end
end

-- Target selector data for targets that pass collision/visibility filters
local target_selector_data_visible = nil
local target_selector_data_all = nil

-- OPTIMIZATION: Pre-cache all spell priorities for instant lookup
local spell_priority_cache = {}
for build_index = 0, 12 do
    spell_priority_cache[build_index] = get_spell_priority(build_index)
end

local current_spell_priority = spell_priority_cache[0]; -- 0 for default build

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
local max_targeting_range = 12.0
local collision_table = { true, 1 } -- collision width
local floor_table = { true, 5.0 }   -- floor height
local angle_table = { false, 90.0 } -- max angle

-- Cache for heavy function results
local next_target_update_time = 0.0 -- Time of next target evaluation
local next_cast_time = 0.0          -- Time of next possible cast
local targeting_refresh_interval = 0.2

-- Default enemy weights for different enemy types
local normal_monster_value = 2
local elite_value = 10
local champion_value = 15
local boss_value = 50
local damage_resistance_value = 25

-- Declare target_selector_data_all to avoid linter errors
local target_selector_data_all = nil

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
    shield_bash = require("spells/shield_bash"),
    spear_of_the_heavens = require("spells/spear_of_the_heavens"),
    zeal = require("spells/zeal"),
    zenith = require("spells/zenith"),
    aegis = require("spells/aegis"),
    fortress = require("spells/fortress"),
    purify = require("spells/purify"),
}

-- OPTIMIZATION: Cache spell data for resource checks
local spell_resource_cache = {}
for spell_name, spell_module in pairs(spells) do
    local data = spell_data[spell_name]
    if data then
        spell_resource_cache[spell_name] = {
            faith_cost = data.faith_cost,
            requires_enemies = data.cast_type ~= "self",                                                               -- Non-self spells generally require targets
            cast_delay = data.cast_delay,                                                                              -- Cache cast delay for faster lookup
            has_priority_targeting = spell_module.menu_elements and spell_module.menu_elements.priority_target ~= nil, -- Cache priority targeting availability
            logics_func = spell_module.logics,                                                                         -- Cache logics function reference
            menu_elements = spell_module
                .menu_elements                                                                                         -- Cache menu elements reference
        }
    end
end

local last_build_index = -1 -- Track build changes for optimization

-- OPTIMIZATION: Pre-compute targeting mode maps for instant lookup
local targeting_mode_maps = {
    melee = {
        [0] = 2, -- Melee Target
        [1] = 3, -- Melee Target (in sight)
        [2] = 4, -- Closest Target
        [3] = 5, -- Closest Target (in sight)
        [4] = 6, -- Best Cursor Target
        [5] = 7  -- Closest Cursor Target
    },
    ranged = {
        [0] = 0, -- Ranged Target
        [1] = 1, -- Ranged Target (in sight)
        [2] = 4, -- Closest Target
        [3] = 5, -- Closest Target (in sight)
        [4] = 6, -- Best Cursor Target
        [5] = 7  -- Closest Cursor Target
    }
}

-- OPTIMIZATION: Pre-compute target unit lookup table
local target_unit_map = {
    [0] = function() return best_ranged_target end,
    [1] = function() return best_ranged_target_visible end,
    [2] = function() return best_melee_target end,
    [3] = function() return best_melee_target_visible end,
    [4] = function() return closest_target end,
    [5] = function() return closest_target_visible end,
    [6] = function() return best_cursor_target end,
    [7] = function() return closest_cursor_target end
}

on_render_menu(function()
    if not menu.menu_elements.main_tree:push("DirtyDio Paladin v2.2.0") then
        return;
    end

    menu.menu_elements.main_boolean:render("Enable Plugin", "");

    if not menu.menu_elements.main_boolean:get() then
        menu.menu_elements.main_tree:pop();
        return;
    end;

    menu.menu_elements.main_debug_enabled:render("Main Debug Mode",
        "Enable for high-verbosity console logging from the main loop")

    if menu.menu_elements.settings_tree:push("Settings") then
        menu.menu_elements.enemy_count_threshold:render("Minimum Enemy Count",
            "       Minimum number of enemies in Enemy Evaluation Radius to consider them for targeting")
        menu.menu_elements.targeting_refresh_interval:render("Targeting Refresh Interval",
            "       Time between target checks in seconds       ", 1)
        menu.menu_elements.max_targeting_range:render("Max Targeting Range",
            "       Maximum range for targeting       ")
        menu.menu_elements.cursor_targeting_radius:render("Cursor Targeting Radius",
            "       Area size for selecting target around the cursor       ", 1)
        menu.menu_elements.cursor_targeting_angle:render("Cursor Targeting Angle",
            "       Maximum angle between cursor and target to cast targetted spells       ")
        menu.menu_elements.best_target_evaluation_radius:render("Enemy Evaluation Radius",
            "       Area size around an enemy to evaluate if it's the best target       \n" ..
            "       If you use huge aoe spells, you should increase this value       \n" ..
            "       Size is displayed with debug/display targets with faded white circles       ", 1)

        menu.menu_elements.build_selector:render("Build Selector",
            { "Default", "Judgement Nuke", "Hammerkuna", "Arbiter", "Captain America", "Shield Bash", "Wing Strikes",
                "Evade Hammer", "Arbiter Evade", "Heaven's Fury", "Spear", "Zenith Tank", "Auradin" },
            "Select a build to optimize spell priorities and timings for max DPS")

        -- Spell priority is now updated in on_update for real-time adjustments

        menu.menu_elements.custom_enemy_weights:render("Custom Enemy Weights",
            "Enable custom enemy weights for determining best targets within Enemy Evaluation Radius")
        if menu.menu_elements.custom_enemy_weights:get() then
            if menu.menu_elements.custom_enemy_weights_tree:push("Custom Enemy Weights") then
                menu.menu_elements.enemy_weight_normal:render("Normal Enemy Weight",
                    "Weighing score for normal enemies - default is 2")
                menu.menu_elements.enemy_weight_elite:render("Elite Enemy Weight",
                    "Weighing score for elite enemies - default is 10")
                menu.menu_elements.enemy_weight_champion:render("Champion Enemy Weight",
                    "Weighing score for champion enemies - default is 15")
                menu.menu_elements.enemy_weight_boss:render("Boss Enemy Weight",
                    "Weighing score for boss enemies - default is 50")
                menu.menu_elements.enemy_weight_damage_resistance:render("Damage Resistance Aura Enemy Weight",
                    "Weighing score for enemies with damage resistance aura - default is 25")
                menu.menu_elements.custom_enemy_weights_tree:pop()
            end
        end

        menu.menu_elements.enable_debug:render("Enable Debug", "")
        menu.menu_elements.file_logging_enabled:render("File Logging", "Enable logging to file for debugging")
        if menu.menu_elements.enable_debug:get() then
            if menu.menu_elements.debug_tree:push("Debug") then
                menu.menu_elements.draw_targets:render("Display Targets", menu.draw_targets_description)
                menu.menu_elements.draw_max_range:render("Display Max Range",
                    "Draw max range circle")
                menu.menu_elements.draw_melee_range:render("Display Melee Range",
                    "Draw melee range circle")
                menu.menu_elements.draw_enemy_circles:render("Display Enemy Circles",
                    "Draw enemy circles")
                menu.menu_elements.draw_cursor_target:render("Display Cursor Target", menu.cursor_target_description)
                menu.menu_elements.debug_tree:pop()
            end
        end

        menu.menu_elements.settings_tree:pop()
    end

    -- Keep menu in sync even if load-order changes; also used by on_update
    refresh_equipped_lookup()

    if menu.menu_elements.spells_tree:push("Equipped Spells") then
        -- Display spells in priority order, but only if they're equipped
        for _, spell_name in ipairs(current_spell_priority) do
            if equipped_lookup[spell_name] or spell_name == "evade" then
                local spell = spells[spell_name]
                if spell then
                    spell.menu()
                end
            end
        end
        menu.menu_elements.spells_tree:pop()
    end

    if menu.menu_elements.disabled_spells_tree:push("Inactive Spells") then
        for _, spell_name in ipairs(current_spell_priority) do
            local spell = spells[spell_name]
            if spell and spell_name ~= "evade" and not equipped_lookup[spell_name] then
                spell.menu()
            end
        end
        menu.menu_elements.disabled_spells_tree:pop()
    end

    menu.menu_elements.main_tree:pop();
end)

local function use_ability(spell_name, delay_after_cast)
    local spell = spells[spell_name]
    if not (spell and spell.menu_elements.main_boolean:get()) then
        return false
    end

    local target_unit = nil
    if spell.menu_elements.targeting_mode then
        local targeting_mode = spell.menu_elements.targeting_mode:get()
        if spell.targeting_type == "melee" then
            targeting_mode = targeting_mode_maps.melee[targeting_mode] or 2
        elseif spell.targeting_type == "ranged" then
            targeting_mode = targeting_mode_maps.ranged[targeting_mode] or 0
        end

        local getter = target_unit_map[targeting_mode]
        if getter then
            target_unit = getter()
        end
    end

    -- Spell logics now return (success, cooldown) like reference repos
    local success, cooldown
    if target_unit then
        success, cooldown = spell.logics(target_unit, target_selector_data_all)
    else
        success, cooldown = spell.logics()
    end

    if success then
        local actual_cooldown = cooldown or delay_after_cast
        next_cast_time = get_time_since_inject() + actual_cooldown
        cast_end_time = get_time_since_inject() + actual_cooldown
        my_utility.record_spell_cast(spell_name)
        return true
    end

    return false
end

local function get_equipped_spell_ids()
    local equipped_spells = {}
    -- Get player spells
    local local_player = get_local_player()
    if local_player then
        local player_spells = local_player:get_spells()
        if player_spells then
            for _, spell in ipairs(player_spells) do
                if spell.is_equipped then
                    table.insert(equipped_spells, spell.spell_id)
                end
            end
        end
    end
    return equipped_spells
end

-- on_update callback
on_update(function()
    -- Update spell priority dynamically every frame for real-time adjustments
    current_spell_priority = spell_priority_cache[menu.menu_elements.build_selector:get()]

    -- Sync debug flag from menu to the utility module
    my_utility.set_debug_enabled(menu.menu_elements.enable_debug:get())

    -- File logging management
    if menu.menu_elements.file_logging_enabled:get() then
        if not logger.is_ready() then
            logger.init()
        end
    else
        if logger.is_ready() then
            logger.close()
        end
    end

    local current_time = get_time_since_inject()
    local local_player = get_local_player()
    if not local_player then
        return;
    end

    -- Only run logic for Paladin (class_id 7, 8, or 9 - all paladin variants in Season 11)
    local character_id = local_player:get_character_class_id();
    local is_paladin = character_id == 7 or character_id == 8 or character_id == 9;
    if not is_paladin then
        return;
    end

    try_init_orbwalker();

    -- Refresh equipped spell lookup periodically so casting doesn't depend on opening the menu.
    if current_time >= next_equipped_refresh_time then
        refresh_equipped_lookup()
        next_equipped_refresh_time = current_time + 0.5
    end

    if menu.menu_elements.main_boolean:get() == false or current_time < next_cast_time then
        return
    end

    if not my_utility.is_action_allowed() then
        return;
    end

    -- Out of combat evade (unchanged)
    if spells.evade and spells.evade.menu_elements.use_out_of_combat:get() then
        spells.evade.out_of_combat()
    end

    targeting_refresh_interval = menu.menu_elements.targeting_refresh_interval:get()
    -- Only update targets if targeting_refresh_interval has expired
    if current_time >= next_target_update_time then
        local player_position = get_player_position()
        max_targeting_range = menu.menu_elements.max_targeting_range:get()

        local entity_list_visible, entity_list = my_target_selector.get_target_list(
            player_position,
            max_targeting_range,
            collision_table,
            floor_table,
            angle_table)

        target_selector_data_all = my_target_selector.get_target_selector_data(
            player_position,
            entity_list)

        target_selector_data_visible = my_target_selector.get_target_selector_data(
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
        if menu.menu_elements.custom_enemy_weights:get() then
            normal_monster_value = menu.menu_elements.enemy_weight_normal:get()
            elite_value = menu.menu_elements.enemy_weight_elite:get()
            champion_value = menu.menu_elements.enemy_weight_champion:get()
            boss_value = menu.menu_elements.enemy_weight_boss:get()
            damage_resistance_value = menu.menu_elements.enemy_weight_damage_resistance:get()
        else
            normal_monster_value = 2
            elite_value = 10
            champion_value = 15
            boss_value = 50
            damage_resistance_value = 25
        end

        -- Check all targets within max range
        if target_selector_data_all and target_selector_data_all.is_valid then
            local config = {
                player_position = player_position,
                cursor_position = get_cursor_position(),
                cursor_targeting_radius = menu.menu_elements.cursor_targeting_radius:get(),
                best_target_evaluation_radius = menu.menu_elements.best_target_evaluation_radius:get(),
                cursor_targeting_angle = menu.menu_elements.cursor_targeting_angle:get(),
                enemy_count_threshold = menu.menu_elements.enemy_count_threshold:get(),
                normal_monster_value = normal_monster_value,
                elite_value = elite_value,
                champion_value = champion_value,
                boss_value = boss_value,
                damage_resistance_value = damage_resistance_value,
                horde_objective_weight = 1000
            }
            best_ranged_target, best_melee_target, best_cursor_target, closest_cursor_target, ranged_max_score,
            melee_max_score, cursor_max_score, closest_cursor_target_angle = target_scoring.evaluate_targets(
                target_selector_data_all.list,
                melee_range,
                config)
            closest_target = target_selector_data_all.closest_unit

            -- Visible/(in sight) targets: use the collision/visibility-filtered list.
            if target_selector_data_visible and target_selector_data_visible.is_valid then
                best_ranged_target_visible, best_melee_target_visible, _, _, ranged_max_score_visible,
                melee_max_score_visible, _, _ = target_scoring.evaluate_targets(
                    target_selector_data_visible.list,
                    melee_range,
                    config)
                closest_target_visible = target_selector_data_visible.closest_unit
            else
                best_ranged_target_visible = nil
                best_melee_target_visible = nil
                closest_target_visible = nil
                ranged_max_score_visible = 0
                melee_max_score_visible = 0
            end
        end

        -- Update next target update time
        next_target_update_time = current_time + targeting_refresh_interval
    end

    -- Ability usage - uses spell_priority to determine the order of spells
    for _, spell_name in ipairs(current_spell_priority) do
        if equipped_lookup[spell_name] then
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
    if menu.menu_elements.main_boolean:get() == false or not menu.menu_elements.main_debug_enabled:get() then
        return;
    end;

    local local_player = get_local_player();
    if not local_player then
        return;
    end

    -- Only render Paladin debug for Paladin
    if local_player:get_character_class_id() ~= 9 then
        return;
    end

    local player_position = local_player:get_position();
    local player_screen_position = graphics.w2s(player_position);
    if player_screen_position:is_zero() then
        return;
    end

    -- Draw max range
    max_targeting_range = menu.menu_elements.max_targeting_range:get()
    if menu.menu_elements.draw_max_range:get() then
        graphics.circle_3d(player_position, max_targeting_range, color_white(85), 2.5, 144)
    end

    -- Draw melee range
    if menu.menu_elements.draw_melee_range:get() then
        local melee_range = my_utility.get_melee_range()
        graphics.circle_3d(player_position, melee_range, color_white(85), 2.5, 144)
    end

    -- Draw enemy circles
    if menu.menu_elements.draw_enemy_circles:get() then
        local enemies = actors_manager.get_enemy_npcs()

        for i, obj in ipairs(enemies) do
            local position = obj:get_position();
            graphics.circle_3d(position, 1, color_white(100));

            local future_position = prediction.get_future_unit_position(obj, 0.4);
            graphics.circle_3d(future_position, 0.25, color_yellow(100));
        end;
    end

    if menu.menu_elements.draw_cursor_target:get() then
        local cursor_position = get_cursor_position()
        local cursor_targeting_radius = menu.menu_elements.cursor_targeting_radius:get()

        -- Draw cursor radius
        graphics.circle_3d(cursor_position, cursor_targeting_radius, color_white(target_evaluation_radius_alpha), 1);
    end

    -- Only draw targets if we have valid target selector data
    if not target_selector_data_all or not target_selector_data_all.is_valid then
        return
    end

    local best_target_evaluation_radius = menu.menu_elements.best_target_evaluation_radius:get()

    -- Draw targets
    if menu.menu_elements.draw_targets:get() then
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

    if menu.menu_elements.draw_cursor_target:get() then
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

console.print("Lua Plugin - DirtyDio Paladin - Version 2.2.0")
