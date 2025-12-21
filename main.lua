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
local logger = require("my_utility/logger");
local get_spell_priority = require("spell_priority");

-- OPTIMIZATION: Pre-cache all spell priorities for instant lookup
local spell_priority_cache = {}
for build_index = 0, 11 do
    spell_priority_cache[build_index] = get_spell_priority(build_index)
end

local current_spell_priority = spell_priority_cache[0]; -- 0 for default build

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

    build_selector                 = combo_box:new(0, get_hash(my_utility.plugin_label .. "build_selector")),

    enable_debug                   = checkbox:new(false, get_hash(my_utility.plugin_label .. "enable_debug")),
    file_logging_enabled           = checkbox:new(false, get_hash(my_utility.plugin_label .. "file_logging_enabled")),
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

    -- Weighted targeting system (inspired by Sorcerer script)
    weighted_targeting_enabled     = checkbox:new(false,
        get_hash(my_utility.plugin_label .. "weighted_targeting_enabled")),
    custom_enemy_sliders_enabled   = checkbox:new(false,
        get_hash(my_utility.plugin_label .. "custom_enemy_sliders_enabled")),
    normal_target_count            = slider_int:new(1, 10, 1,
        get_hash(my_utility.plugin_label .. "normal_target_count")),
    champion_target_count          = slider_int:new(1, 10, 1,
        get_hash(my_utility.plugin_label .. "champion_target_count")),
    elite_target_count             = slider_int:new(1, 10, 1,
        get_hash(my_utility.plugin_label .. "elite_target_count")),
    boss_target_count              = slider_int:new(1, 10, 1,
        get_hash(my_utility.plugin_label .. "boss_target_count")),
    scan_radius                    = slider_float:new(1, 30, 12, get_hash(my_utility.plugin_label .. "scan_radius")),
    targeting_refresh_rate         = slider_float:new(0.1, 1, 0.2,
        get_hash(my_utility.plugin_label .. "targeting_refresh_rate")),
    min_targets                    = slider_int:new(1, 10, 1, get_hash(my_utility.plugin_label .. "min_targets")),
    comparison_radius              = slider_float:new(0.1, 6, 3, get_hash(my_utility.plugin_label .. "comparison_radius")),
    horde_objective_weight         = slider_int:new(1, 1000, 1000,
        get_hash(my_utility.plugin_label .. "horde_objective_weight")),

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
            .menu_elements                                                                                             -- Cache menu elements reference
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
    if not menu_elements.main_tree:push("DirtyDio v2.2.0") then
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

        menu_elements.build_selector:render("Build Selector",
            { "Default", "Judgement Nuke", "Hammerkuna", "Arbiter", "Captain America", "Shield Bash", "Wing Strikes",
                "Evade Hammer", "Arbiter Evade", "Heaven's Fury", "Spear", "Zenith Tank", "Auradin" },
            "Select a build to optimize spell priorities and timings for max DPS")

        -- Spell priority is now updated in on_update for real-time adjustments

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

        -- Weighted targeting system (enhanced version)
        menu_elements.weighted_targeting_enabled:render("Advanced Weighted Targeting",
            "Enable enhanced weighted targeting system with additional controls")
        if menu_elements.weighted_targeting_enabled:get() then
            menu_elements.scan_radius:render("Scan Radius", "Radius around character to scan for targets (1-30)")
            menu_elements.targeting_refresh_rate:render("Refresh Rate",
                "How often to refresh target scanning in seconds (0.1-1.0)", 1)
            menu_elements.min_targets:render("Minimum Targets",
                "Minimum number of targets required to activate weighted targeting (1-10)")
            menu_elements.comparison_radius:render("Comparison Radius",
                "Radius to check for nearby targets when calculating weights (0.1-6.0)", 1)
            menu_elements.horde_objective_weight:render("Horde Objective Weight",
                "Bonus weight for infernal horde objectives (1-1000)")

            menu_elements.custom_enemy_sliders_enabled:render("Custom Enemy Sliders",
                "Enable custom sliders for enemy type target counts")
            if menu_elements.custom_enemy_sliders_enabled:get() then
                menu_elements.normal_target_count:render("Normal Target Count",
                    "Maximum number of normal enemies to target (0-20)")
                menu_elements.champion_target_count:render("Champion Target Count",
                    "Maximum number of champion enemies to target (0-10)")
                menu_elements.elite_target_count:render("Elite Target Count",
                    "Maximum number of elite enemies to target (0-10)")
                menu_elements.boss_target_count:render("Boss Target Count",
                    "Maximum number of boss enemies to target (0-5)")
            end
        end

        menu_elements.enable_debug:render("Enable Debug", "")
        menu_elements.file_logging_enabled:render("File Logging", "Enable logging to file for debugging")
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

local target_scoring = require('my_utility/target_scoring')

local function evaluate_targets(target_list, melee_range)
    local cfg = {
        player_position = get_player_position(),
        cursor_position = get_cursor_position(),
        cursor_targeting_radius = menu_elements.cursor_targeting_radius:get(),
        best_target_evaluation_radius = menu_elements.best_target_evaluation_radius:get(),
        cursor_targeting_angle = menu_elements.cursor_targeting_angle:get(),
        enemy_count_threshold = menu_elements.enemy_count_threshold:get(),
        normal_monster_value = normal_monster_value,
        elite_value = elite_value,
        champion_value = champion_value,
        boss_value = boss_value,
        damage_resistance_value = damage_resistance_value,
        horde_objective_weight = menu_elements.weighted_targeting_enabled:get() and
            menu_elements.horde_objective_weight:get() or 1000
    }
    return target_scoring.evaluate_targets(target_list, melee_range, cfg)
end

local function use_ability(spell_name, delay_override, debug_enabled, file_logging_enabled)
    -- OPTIMIZATION: Use cached spell data
    local resource_data = spell_resource_cache[spell_name]
    if not resource_data then return false end

    local spell = spells[spell_name]
    local menu_elements = resource_data.menu_elements
    if not (menu_elements and menu_elements.main_boolean and menu_elements.main_boolean:get()) then
        return false
    end

    -- compute delay: preference order -> explicit override argument, spell menu cast_delay, cached spell_data cast_delay, spell_data cast_type mapping
    local delay = delay_override
    if not delay then
        if menu_elements.cast_delay and type(menu_elements.cast_delay.get) == "function" then
            delay = menu_elements.cast_delay:get()
        elseif resource_data.cast_delay then
            delay = resource_data.cast_delay
        else
            local sd = spell_data[spell_name]
            if sd and sd.cast_delay then
                delay = sd.cast_delay
            elseif sd and sd.cast_type == "self" then
                delay = my_utility.spell_delays.instant_cast
            else
                delay = my_utility.spell_delays.regular_cast
            end
        end
    end

    local target_unit = nil
    if spell.menu_elements.targeting_mode then
        local targeting_mode = spell.menu_elements.targeting_mode:get()

        -- OPTIMIZATION: Use pre-computed targeting mode maps
        if spell.targeting_type == "melee" then
            targeting_mode = targeting_mode_maps.melee[targeting_mode] or 2  -- Default to Melee Target
        elseif spell.targeting_type == "ranged" then
            targeting_mode = targeting_mode_maps.ranged[targeting_mode] or 0 -- Default to Ranged Target
        end

        -- OPTIMIZATION: Use pre-computed target unit lookup
        target_unit = target_unit_map[targeting_mode] and target_unit_map[targeting_mode]() or nil
    end

    --if target_unit is nil, it means the spell is not targetted and we use the default logic without target
    local success, returned_cooldown = nil, nil
    if target_unit then
        -- OPTIMIZATION: Use cached priority targeting check and logics function
        if resource_data.has_priority_targeting and menu_elements.priority_target:get() then
            success, returned_cooldown = resource_data.logics_func(target_unit, target_selector_data_all)
        else
            success, returned_cooldown = resource_data.logics_func(target_unit)
        end
    else
        success, returned_cooldown = resource_data.logics_func()
    end
    if success then
        local cd_to_use = returned_cooldown or delay
        next_cast_time = get_time_since_inject() + cd_to_use
        my_utility.record_spell_cast(spell_name)

        -- Enhanced debug logging for spell casts
        if debug_enabled then
            local target_info = target_unit and " on target" or " (no target)"
            console.print("Spell cast: " .. spell_name .. target_info .. " | Cooldown: " .. cd_to_use .. "s")
            if file_logging_enabled then
                logger.log("Spell cast: " .. spell_name .. target_info .. " | Cooldown: " .. cd_to_use .. "s")
            end
        end

        return true
    end

    return false
end

-- Enhanced weighted targeting system inspired by Sorcerer repo
local function evaluate_targets(entity_list, melee_range, config)
    local best_ranged_target = nil
    local best_melee_target = nil
    local best_cursor_target = nil
    local closest_cursor_target = nil
    local ranged_max_score = 0
    local melee_max_score = 0
    local cursor_max_score = 0
    local closest_cursor_target_angle = 0

    if not entity_list or #entity_list == 0 then
        return best_ranged_target, best_melee_target, best_cursor_target, closest_cursor_target,
            ranged_max_score, melee_max_score, cursor_max_score, closest_cursor_target_angle
    end

    -- Count enemies by type for weighted targeting
    local enemy_counts = { normal = 0, elite = 0, champion = 0, boss = 0 }
    for _, unit in ipairs(entity_list) do
        if unit:is_boss() then
            enemy_counts.boss = enemy_counts.boss + 1
        elseif unit:is_champion() then
            enemy_counts.champion = enemy_counts.champion + 1
        elseif unit:is_elite() then
            enemy_counts.elite = enemy_counts.elite + 1
        else
            enemy_counts.normal = enemy_counts.normal + 1
        end
    end

    -- Check if we have minimum targets for weighted targeting
    local total_enemies = #entity_list
    local use_weighted_targeting = menu_elements.weighted_targeting_enabled:get() and
        total_enemies >= config.enemy_count_threshold

    if use_weighted_targeting and menu_elements.enable_debug:get() then
        console.print("Weighted Targeting: " ..
            total_enemies .. " enemies found, threshold: " .. config.enemy_count_threshold)
    end

    -- Apply custom enemy sliders if enabled
    local max_normal = use_weighted_targeting and menu_elements.custom_enemy_sliders_enabled:get() and
        menu_elements.normal_target_count:get() or math.huge
    local max_elite = use_weighted_targeting and menu_elements.custom_enemy_sliders_enabled:get() and
        menu_elements.elite_target_count:get() or math.huge
    local max_champion = use_weighted_targeting and menu_elements.custom_enemy_sliders_enabled:get() and
        menu_elements.champion_target_count:get() or math.huge
    local max_boss = use_weighted_targeting and menu_elements.custom_enemy_sliders_enabled:get() and
        menu_elements.boss_target_count:get() or math.huge

    -- Filter targets based on custom sliders
    local filtered_targets = {}
    local current_counts = { normal = 0, elite = 0, champion = 0, boss = 0 }

    for _, unit in ipairs(entity_list) do
        local can_add = true
        if unit:is_boss() and current_counts.boss >= max_boss then
            can_add = false
        elseif unit:is_champion() and current_counts.champion >= max_champion then
            can_add = false
        elseif unit:is_elite() and current_counts.elite >= max_elite then
            can_add = false
        elseif not unit:is_boss() and not unit:is_champion() and not unit:is_elite() and
            current_counts.normal >= max_normal then
            can_add = false
        end

        if can_add then
            table.insert(filtered_targets, unit)
            if unit:is_boss() then
                current_counts.boss = current_counts.boss + 1
            elseif unit:is_champion() then
                current_counts.champion = current_counts.champion + 1
            elseif unit:is_elite() then
                current_counts.elite = current_counts.elite + 1
            else
                current_counts.normal = current_counts.normal + 1
            end
        end
    end

    -- Use filtered targets or original list
    local targets_to_evaluate = use_weighted_targeting and filtered_targets or entity_list

    if use_weighted_targeting and menu_elements.enable_debug:get() then
        console.print("Filtered targets: Normal=" .. current_counts.normal .. "/" .. max_normal ..
            ", Elite=" .. current_counts.elite .. "/" .. max_elite ..
            ", Champion=" .. current_counts.champion .. "/" .. max_champion ..
            ", Boss=" .. current_counts.boss .. "/" .. max_boss)
    end

    for _, unit in ipairs(targets_to_evaluate) do
        local unit_position = unit:get_position()
        local distance_to_player = unit_position:squared_dist_to_ignore_z(config.player_position)

        -- Calculate base score using existing weights
        local score = 0
        if unit:is_boss() then
            score = config.boss_value
        elseif unit:is_champion() then
            score = config.champion_value
        elseif unit:is_elite() then
            score = config.elite_value
        else
            score = config.normal_monster_value
        end

        -- Add horde objective bonus if applicable
        if my_utility.is_horde_objective(unit) then
            score = score + config.horde_objective_weight
        end

        -- Add damage resistance bonus
        if unit:has_buff_with_name_hash(0x12345678) then -- Placeholder for damage resistance buff
            score = score + config.damage_resistance_value
        end

        -- Distance penalty for ranged targeting
        local distance_penalty = distance_to_player / 1000 -- Normalize distance
        local ranged_score = score - distance_penalty

        -- Distance bonus for melee targeting (closer is better)
        local melee_score = score + (1000 - distance_penalty)

        -- Update best ranged target
        if ranged_score > ranged_max_score then
            best_ranged_target = unit
            ranged_max_score = ranged_score
        end

        -- Update best melee target
        if distance_to_player <= melee_range * melee_range and melee_score > melee_max_score then
            best_melee_target = unit
            melee_max_score = melee_score
        end

        -- Cursor targeting logic
        local distance_to_cursor = unit_position:squared_dist_to_ignore_z(config.cursor_position)
        if distance_to_cursor <= config.cursor_targeting_radius * config.cursor_targeting_radius then
            local direction_to_unit = unit_position - config.cursor_position
            local angle = math.abs(math.atan2(direction_to_unit:y(), direction_to_unit:x()))
            if angle <= config.cursor_targeting_angle then
                local cursor_score = score + (1000 - distance_to_cursor / 10)
                if cursor_score > cursor_max_score then
                    best_cursor_target = unit
                    cursor_max_score = cursor_score
                end

                -- Track closest cursor target
                if not closest_cursor_target or distance_to_cursor < closest_cursor_target_distance then
                    closest_cursor_target = unit
                    closest_cursor_target_distance = distance_to_cursor
                    closest_cursor_target_angle = angle
                end
            end
        end
    end

    return best_ranged_target, best_melee_target, best_cursor_target, closest_cursor_target,
        ranged_max_score, melee_max_score, cursor_max_score, closest_cursor_target_angle
end

-- on_update callback
on_update(function()
    -- Update spell priority only when build changes (optimization)
    local current_build = menu_elements.build_selector:get()
    if current_build ~= last_build_index then
        current_spell_priority = spell_priority_cache[current_build]
        last_build_index = current_build
        -- Reset spell cast tracking when build changes
        my_utility.reset_spell_cast_tracking()
    end

    -- Sync debug flag from menu to the utility module
    my_utility.set_debug_enabled(menu_elements.enable_debug:get())

    -- File logging management
    if menu_elements.file_logging_enabled:get() then
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
    if not local_player or menu_elements.main_boolean:get() == false or current_time < next_cast_time then
        return
    end

    if not my_utility.is_action_allowed() then
        return;
    end

    -- Out of combat evade (unchanged)
    if spells.evade and spells.evade.menu_elements.use_out_of_combat:get() then
        spells.evade.out_of_combat()
    end

    targeting_refresh_interval = menu_elements.targeting_refresh_interval:get()
    -- OPTIMIZATION: Reduced default targeting refresh rate for better responsiveness
    if targeting_refresh_interval > 0.15 then
        targeting_refresh_interval = 0.15 -- Cap at 0.15s for optimal performance
    end
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
            local config = {
                player_position = player_position,
                cursor_position = get_cursor_position(),
                cursor_targeting_radius = menu_elements.cursor_targeting_radius:get(),
                best_target_evaluation_radius = menu_elements.weighted_targeting_enabled:get() and
                    menu_elements.comparison_radius:get() or menu_elements.best_target_evaluation_radius:get(),
                cursor_targeting_angle = menu_elements.cursor_targeting_angle:get(),
                enemy_count_threshold = menu_elements.weighted_targeting_enabled:get() and
                    menu_elements.min_targets:get() or menu_elements.enemy_count_threshold:get(),
                normal_monster_value = normal_monster_value,
                elite_value = elite_value,
                champion_value = champion_value,
                boss_value = boss_value,
                damage_resistance_value = damage_resistance_value,
                horde_objective_weight = menu_elements.weighted_targeting_enabled:get() and
                    menu_elements.horde_objective_weight:get() or 1000
            }
            best_ranged_target, best_melee_target, best_cursor_target, closest_cursor_target, ranged_max_score,
            melee_max_score, cursor_max_score, closest_cursor_target_angle = evaluate_targets(
                target_selector_data_all.list,
                melee_range,
                config)
            closest_target = target_selector_data_all.closest_unit
        end


        -- Check visible targets within max range
        if target_selector_data_visible and target_selector_data_visible.is_valid then
            local config_visible = {
                player_position = player_position,
                cursor_position = get_cursor_position(),
                cursor_targeting_radius = menu_elements.cursor_targeting_radius:get(),
                best_target_evaluation_radius = menu_elements.weighted_targeting_enabled:get() and
                    menu_elements.comparison_radius:get() or menu_elements.best_target_evaluation_radius:get(),
                cursor_targeting_angle = menu_elements.cursor_targeting_angle:get(),
                enemy_count_threshold = menu_elements.weighted_targeting_enabled:get() and
                    menu_elements.min_targets:get() or menu_elements.enemy_count_threshold:get(),
                normal_monster_value = normal_monster_value,
                elite_value = elite_value,
                champion_value = champion_value,
                boss_value = boss_value,
                damage_resistance_value = damage_resistance_value,
                horde_objective_weight = menu_elements.weighted_targeting_enabled:get() and
                    menu_elements.horde_objective_weight:get() or 1000
            }
            best_ranged_target_visible, best_melee_target_visible, _, _,
            ranged_max_score_visible, melee_max_score_visible, _ = evaluate_targets(
                target_selector_data_visible.list,
                melee_range,
                config_visible)
            closest_target_visible = target_selector_data_visible.closest_unit
        end

        -- Update next target update time
        next_target_update_time = current_time + targeting_refresh_interval
    end

    -- OPTIMIZATION: Pre-check resource availability and spell readiness
    local player_faith = local_player:get_important_resource(enum_important_resource.resource_faith)
    local has_enemies = (best_ranged_target or best_melee_target) ~= nil
    local debug_enabled = menu_elements.enable_debug:get()
    local file_logging_enabled = menu_elements.file_logging_enabled:get()

    -- Ability usage - optimized spell priority loop with early exits
    for _, spell_name in ipairs(current_spell_priority) do
        -- OPTIMIZATION: Use cached resource data for instant checks
        local resource_data = spell_resource_cache[spell_name]
        if resource_data then
            -- Early resource check for faith-costing spells
            if resource_data.faith_cost and player_faith < resource_data.faith_cost then
                -- Skip faith-costing spells if we don't have enough faith
            elseif resource_data.requires_enemies and not has_enemies then
                -- Skip spells that require enemies when none are present
            elseif use_ability(spell_name, nil, debug_enabled, file_logging_enabled) then
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

    -- Draw weighted targeting scan radius
    if menu_elements.weighted_targeting_enabled:get() and menu_elements.enable_debug:get() then
        local scan_radius = menu_elements.scan_radius:get()
        graphics.circle_3d(player_position, scan_radius, color_cyan(50), 1.0, 64)
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

my_utility.debug_print("Lua Plugin - DirtyDio - Version 2.2.0")
