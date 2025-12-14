-- =====================================================
-- PALADIN ROTATION SCRIPT (Season 11)
-- Based on "Sorc_Rota_salad" architecture and Druid/Spiritborn reference repos.
--
-- REVIEW & OPTIMIZATION (Dec 2025):
-- 1. Validated against Season 11 Paladin/Spiritborn API.
-- 2. Optimized Blessed Hammer logic to rely on centralized movement (removed explicit move).
-- 3. Standardized cursor position handling in my_utility.
-- 4. Verified Weighted Targeting integration in main loop.
-- 5. Confirmed "Fairness Rotation System" prevents spell starvation.
--
-- FEATURES:
-- 1. Centralized Target Evaluation (evaluate_all_targets):
--    - Scans targets once per tick for efficiency.
--    - Supports Weighted Targeting (Cluster/Priority) system.
--    - Implements Visibility and Elevation filters.
--
-- 2. Fairness Rotation System:
--    - Uses internal cooldowns (spell_internal_cooldowns) to prevent high-priority spell spam.
--    - Ensures all equipped spells get a chance to cast.
--
-- 3. Centralized Movement (my_utility.move_to_target):
--    - Prevents oscillation between different modules trying to move.
--    - Respects "Manual Play" and Orbwalker modes.
--
-- 4. Global State Coordination (_G.PaladinRotation):
--    - Exposes combat state for Looteer and other external modules.
--    - Optimizes target scanning by sharing valid_enemies list.
-- =====================================================

if package and package.loaded then
    package.loaded["menu"] = nil
    package.loaded["spell_priority"] = nil
    package.loaded["my_utility/my_utility"] = nil
    package.loaded["my_utility/spell_data"] = nil
    package.loaded["my_utility/buff_cache"] = nil
    package.loaded["my_utility/my_target_selector"] = nil
    package.loaded["spells/holy_bolt"] = nil
    package.loaded["spells/blessed_hammer"] = nil
    package.loaded["spells/blessed_shield"] = nil
    package.loaded["spells/falling_star"] = nil
    package.loaded["spells/arbiter_of_justice"] = nil
    package.loaded["spells/rally"] = nil
    package.loaded["spells/defiance_aura"] = nil
    package.loaded["spells/fanaticism_aura"] = nil
    package.loaded["spells/holy_light_aura"] = nil
    package.loaded["spells/zeal"] = nil
    package.loaded["spells/clash"] = nil
    package.loaded["spells/shield_charge"] = nil
    package.loaded["spells/spear_of_the_heavens"] = nil
    package.loaded["spells/divine_lance"] = nil
    package.loaded["spells/brandish"] = nil
    -- New spells added from research
    package.loaded["spells/condemn"] = nil
    package.loaded["spells/consecration"] = nil
    package.loaded["spells/heavens_fury"] = nil
    package.loaded["spells/zenith"] = nil
    package.loaded["spells/advance"] = nil
end

-- Early class check (like sorc/barb)
-- Paladin Class ID: 7 (Spiritborn/Paladin)
-- Class IDs: Sorcerer=0, Barbarian=1, Rogue=3, Druid=5, Necromancer=6, Spiritborn/Paladin=7
-- We do NOT return early here to ensure callbacks are registered even if player isn't ready yet
local is_paladin_checked = false
local is_paladin_class = false

-- Orbwalker settings (like druid/barb) - take control of movement
-- These MUST be called unconditionally at the top level, before any logic
-- set_block_movement(true): We handle all movement in spell logics, not orbwalker
-- set_clear_toggle(true): Allow the clear mode toggle to work
if orbwalker and orbwalker.set_block_movement then
    pcall(function() orbwalker.set_block_movement(true) end)
end
if orbwalker and orbwalker.set_clear_toggle then
    pcall(function() orbwalker.set_clear_toggle(true) end)
end

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local spell_priority = require("spell_priority")
local menu = require("menu")
local my_target_selector = require("my_utility/my_target_selector")

-- Menu helper must exist before any callbacks that read menu state
local function safe_get_menu_element(element, fallback)
    if element and type(element.get) == "function" then
        return element:get()
    end
    return fallback
end

-- GLOBAL STATE FOR LOOTEER COORDINATION
-- Looteer checks this before looting to avoid conflicts with combat
-- When in_combat=true or is_casting=true, Looteer should defer looting
_G.PaladinRotation = {
    in_combat = false,      -- True when we have valid combat targets
    is_casting = false,     -- True when we're in cast animation
    last_cast_time = 0,     -- Time of last successful cast
    current_target_id = nil, -- ID of current target for coordination
    debug = {}              -- Store debug timers here to avoid global pollution
}

local function update_global_flags_from_menu()
    if not menu or not menu.menu_elements then return end
    _G.PaladinRotation.manual_play = safe_get_menu_element(menu.menu_elements.manual_play, false)
    _G.PaladinRotation.boss_burn_mode = safe_get_menu_element(menu.menu_elements.boss_burn_mode, false)
    _G.PaladinRotation.disable_cursor_priority = safe_get_menu_element(menu.menu_elements.disable_cursor_priority, false)
end

local function safe_on_render_menu(cb)
    if type(on_render_menu) == "function" then
        return on_render_menu(cb)
    end
    return false
end

local function safe_on_update(cb)
    if type(on_update) == "function" then
        return on_update(cb)
    end
    return false
end

local spells = {
    -- Basic Skills (Resource Generators)
    holy_bolt = require("spells/holy_bolt"),
    zeal = require("spells/zeal"),
    advance = require("spells/advance"),           -- Lunge mobility/generator
    clash = require("spells/clash"),               -- Shield bash generator
    
    -- Core Skills (Main Damage)
    blessed_hammer = require("spells/blessed_hammer"),
    blessed_shield = require("spells/blessed_shield"), -- Bouncing shield throw
    divine_lance = require("spells/divine_lance"),
    brandish = require("spells/brandish"),
    
    -- Aura Skills (Buff Maintenance)
    defiance_aura = require("spells/defiance_aura"),
    fanaticism_aura = require("spells/fanaticism_aura"),
    holy_light_aura = require("spells/holy_light_aura"),
    
    -- Valor Skills (Utility/Mobility)
    shield_charge = require("spells/shield_charge"),
    rally = require("spells/rally"),
    
    -- Justice Skills (Damage/Control)
    spear_of_the_heavens = require("spells/spear_of_the_heavens"),
    falling_star = require("spells/falling_star"),
    condemn = require("spells/condemn"),           -- NEW: Pull + Stun AoE
    consecration = require("spells/consecration"), -- NEW: Ground heal + damage
    
    -- Ultimate Skills
    arbiter_of_justice = require("spells/arbiter_of_justice"),
    heavens_fury = require("spells/heavens_fury"), -- NEW: Judicator Ultimate
    zenith = require("spells/zenith"),             -- NEW: Zealot Ultimate
}

local function dbg(msg)
    local enabled = safe_get_menu_element(menu.menu_elements.enable_debug, false)
    if enabled and console and type(console.print) == "function" then
        console.print("[Paladin_Rotation] " .. msg)
    end
end

-- Evaluate all target types for the per-spell targeting system
-- This runs once per update tick and returns all possible targets
local function evaluate_all_targets(player_pos, melee_range, max_range)
    -- Get weights from menu
    local weights = {
        normal = safe_get_menu_element(menu.menu_elements.any_weight, 2),
        elite = safe_get_menu_element(menu.menu_elements.elite_weight, 10),
        champion = safe_get_menu_element(menu.menu_elements.champion_weight, 15),
        boss = safe_get_menu_element(menu.menu_elements.boss_weight, 50),
        comparison_radius = safe_get_menu_element(menu.menu_elements.comparison_radius, 3.0)
    }
    
    -- Get visibility/elevation filter settings
    local filters = {
        check_floor = safe_get_menu_element(menu.menu_elements.enable_floor_filter, true),
        floor_height = safe_get_menu_element(menu.menu_elements.floor_height_threshold, 5.0),
        check_visibility = safe_get_menu_element(menu.menu_elements.enable_visibility_filter, true),
        visibility_width = safe_get_menu_element(menu.menu_elements.visibility_collision_width, 1.0)
    }
    
    local cursor_pos = get_cursor_position and get_cursor_position() or nil
    
    -- Use the centralized target selector logic
    return my_target_selector.get_best_targets(player_pos, melee_range, max_range, cursor_pos, weights, filters)
end



safe_on_render_menu(function()
    if not menu.menu_elements.main_tree:push("Paladin_Rotation") then
        return
    end

    update_global_flags_from_menu()

    menu.menu_elements.main_boolean:render("Enable Plugin", "")
    if not safe_get_menu_element(menu.menu_elements.main_boolean, false) then
        menu.menu_elements.main_tree:pop()
        return
    end

    -- Weighted Targeting System menu
    if menu.menu_elements.weighted_targeting_tree:push("Weighted Targeting System") then
        menu.menu_elements.weighted_targeting_debug:render("Debug Mode", "Enable high-verbosity console logging for weighted targeting decisions")
        menu.menu_elements.weighted_targeting_enabled:render("Enable Weighted Targeting", "Enables the weighted targeting system that prioritizes targets based on type and proximity")
        
        -- Only show configuration if weighted targeting is enabled
        if menu.menu_elements.weighted_targeting_enabled:get() then
            -- Scan settings (scan_radius is now in Settings section - always visible)
            menu.menu_elements.scan_refresh_rate:render("Refresh Rate", "How often to refresh target scanning in seconds (0.1-1.0)", 1)
            menu.menu_elements.min_targets:render("Minimum Targets", "Minimum number of targets required to activate weighted targeting (1-10)")
            menu.menu_elements.comparison_radius:render("Comparison Radius", "Radius to check for nearby targets when calculating weights (0.1-6.0)", 1)
            
            -- Custom Enemy Sliders toggle
            menu.menu_elements.custom_enemy_sliders_enabled:render("Custom Enemy Sliders", "Enable to customize target counts and weights for different enemy types")
            
            -- Only show sliders if custom enemy sliders are enabled
            if menu.menu_elements.custom_enemy_sliders_enabled:get() then
                -- Normal Enemy
                menu.menu_elements.normal_target_count:render("Normal Target Count", "Target count value for normal enemies (1-10)")
                menu.menu_elements.any_weight:render("Normal Weight", "Weight assigned to normal targets (1-100)")
                
                -- Elite Enemy
                menu.menu_elements.elite_target_count:render("Elite Target Count", "Target count value for elite enemies (1-10)")
                menu.menu_elements.elite_weight:render("Elite Weight", "Weight assigned to elite targets (1-100)")
                
                -- Champion Enemy
                menu.menu_elements.champion_target_count:render("Champion Target Count", "Target count value for champion enemies (1-10)")
                menu.menu_elements.champion_weight:render("Champion Weight", "Weight assigned to champion targets (1-100)")
                
                -- Boss Enemy
                menu.menu_elements.boss_target_count:render("Boss Target Count", "Target count value for boss enemies (1-10)")
                menu.menu_elements.boss_weight:render("Boss Weight", "Weight assigned to boss targets (1-100)")
            end
            -- Custom Buff Weights section
            menu.menu_elements.custom_buff_weights_enabled:render("Custom Buff Weights", "Enable to customize weights for special buff-related targets")
            if menu.menu_elements.custom_buff_weights_enabled:get() then
                menu.menu_elements.damage_resistance_provider_weight:render("Damage Resistance Provider Bonus", "Weight bonus for enemies providing damage resistance aura (1-100)")
                menu.menu_elements.damage_resistance_receiver_penalty:render("Damage Resistance Receiver Penalty", "Weight penalty for enemies receiving damage resistance (0-20)")
                menu.menu_elements.horde_objective_weight:render("Horde Objective Bonus", "Weight bonus for infernal horde objective targets (1-100)")
                menu.menu_elements.vulnerable_debuff_weight:render("Vulnerable Debuff Bonus", "Weight bonus for targets with VulnerableDebuff (1-5)")
            end
        end
        
        menu.menu_elements.weighted_targeting_tree:pop()
    end
    
    -- Visibility & Elevation Filtering (matches Druid/Spiritborn reference repos)
    if menu.menu_elements.visibility_tree:push("Visibility & Elevation") then
        menu.menu_elements.enable_floor_filter:render("Enable Floor/Elevation Filter", "Skip targets on different floors (z-axis height difference). Prevents targeting enemies above/below on different levels.")
        if menu.menu_elements.enable_floor_filter:get() then
            menu.menu_elements.floor_height_threshold:render("Floor Height Threshold", "Maximum Z-axis height difference (units). Targets beyond this are ignored. Default: 5.0", 1)
        end
        menu.menu_elements.enable_visibility_filter:render("Enable Visibility Filter", "Check line-of-sight before targeting. Filters out enemies behind walls.")
        if menu.menu_elements.enable_visibility_filter:get() then
            menu.menu_elements.visibility_collision_width:render("Collision Check Width", "Width for wall collision check (units). Larger = stricter. Default: 1.0", 1)
        end
        menu.menu_elements.visibility_tree:pop()
    end

    if menu.menu_elements.settings_tree:push("Settings") then
        -- SCAN RADIUS: How far to look for potential targets
        -- This is ALWAYS shown - it's the primary range setting
        menu.menu_elements.scan_radius:render("Scan Radius", "How far to search for enemies (units). Spells have their own cast ranges within this.")
        
        -- Legacy setting - only show if weighted targeting is disabled
        if not menu.menu_elements.weighted_targeting_enabled:get() then
            if menu.menu_elements.prefer_elites then
                menu.menu_elements.prefer_elites:render("Prefer Elites/Champions/Boss", "")
            end
            if menu.menu_elements.cluster_radius then
                menu.menu_elements.cluster_radius:render("Cluster Radius", "", 1)
            end
        end

        if menu.menu_elements.treat_elite_as_boss then
            menu.menu_elements.treat_elite_as_boss:render("Treat Elite As Boss", "Treat Elite enemies as Bosses for logic purposes")
        end
        
        menu.menu_elements.combo_enemy_count:render("Combo Enemy Count", "", 0)
        menu.menu_elements.combo_window:render("Combo Window", "", 2)
        menu.menu_elements.rally_resource_pct:render("Rally Resource %", "", 2)
        if menu.menu_elements.holy_bolt_resource_pct then
            menu.menu_elements.holy_bolt_resource_pct:render("Holy Bolt Resource %", "", 2)
        end
        if menu.menu_elements.boss_defiance_hp_pct then
            menu.menu_elements.boss_defiance_hp_pct:render("Boss Defiance HP %", "", 2)
        end

        -- QoL toggles
        if menu.menu_elements.boss_burn_mode then
            menu.menu_elements.boss_burn_mode:render("Boss Burn Mode", "Ignore generator resource throttles on elites/bosses to keep APM high")
        end
        if menu.menu_elements.disable_cursor_priority then
            menu.menu_elements.disable_cursor_priority:render("Disable Cursor Priority", "Turn off cursor snap targeting (useful for single-target bossing)")
        end
        
        -- Manual Play Mode
        menu.menu_elements.manual_play:render("Manual Play", "When enabled, disables automatic movement for melee spells - you control positioning manually")
        
        menu.menu_elements.settings_tree:pop()
    end

    -- Debug Options
    menu.menu_elements.enable_debug:render("Debug", "")
    menu.menu_elements.melee_debug_mode:render("Melee Debug Mode", "Enable detailed console logging for melee spell movement and casting decisions")
    menu.menu_elements.bypass_equipped_check:render("Bypass Equipped Check", "DEBUG: Skip checking if spell is equipped - helps identify spell ID issues")

    -- Get equipped spells
    local equipped_spells = get_equipped_spell_ids() or {}

    -- Create a lookup table for equipped spells
    local equipped_lookup = {}
    for _, spell_id in ipairs(equipped_spells) do
        equipped_lookup[spell_id] = true
    end

    if menu.menu_elements.active_spells_tree:push("Active Spells") then
        for _, spell_name in ipairs(spell_priority) do
            local spell = spells[spell_name]
            if spell and spell.menu and spell_data[spell_name] and spell_data[spell_name].spell_id and equipped_lookup[spell_data[spell_name].spell_id] then
                spell.menu()
            end
        end
        menu.menu_elements.active_spells_tree:pop()
    end

    if menu.menu_elements.inactive_spells_tree:push("Inactive Spells") then
        for _, spell_name in ipairs(spell_priority) do
            local spell = spells[spell_name]
            if spell and spell.menu and spell_data[spell_name] and spell_data[spell_name].spell_id and not equipped_lookup[spell_data[spell_name].spell_id] then
                spell.menu()
            end
        end
        menu.menu_elements.inactive_spells_tree:pop()
    end

    menu.menu_elements.main_tree:pop()
end)

local cast_end_time = 0.0
local spell_last_cast_times = {}  -- Per-spell internal cooldown tracking
-- Movement is now centralized in my_utility.move_to_target()

-- Cache evaluated targets to reduce per-frame work and target thrashing
local targets_cache = { data = nil, time = 0.0, melee_range = 0.0, scan_radius = 0.0 }

-- TARGET STICKINESS: Prevent oscillation by sticking to a target for a minimum time
local sticky_target = nil
local sticky_target_time = 0.0
local sticky_duration = 0.75  -- Stay on same target for at least 0.75s
local last_cast_target = nil  -- Track target we last successfully cast at

-- =====================================================
-- SPELL ROTATION FAIRNESS SYSTEM
-- Ensures all equipped spells get a chance to cast, not just the first one
-- Without this, blessed_hammer (0.05s ICD) would dominate and other spells never cast
-- =====================================================
local last_spell_cast_name = nil  -- Track which spell cast last
local spell_cast_counts = {}       -- Count of casts per spell (for weighted fairness)

-- Internal cooldowns (minimum time between casts of same spell)
-- These control how often each spell can be CHECKED for casting
local spell_internal_cooldowns = {
    -- CORE SPAM
    blessed_hammer = 0.08,
    
    -- ALTERNATIVE CORE SPENDERS
    blessed_shield = 0.12,
    zeal = 0.10,
    divine_lance = 0.12,
    
    -- ULTIMATES
    arbiter_of_justice = 0.20,
    heavens_fury = 0.20,
    zenith = 0.20,
    
    -- AURAS
    fanaticism_aura = 0.50,
    defiance_aura = 0.50,
    holy_light_aura = 0.50,
    
    -- BURST COOLDOWNS
    falling_star = 0.10,
    spear_of_the_heavens = 0.20,
    condemn = 0.10,
    consecration = 0.30,
    
    -- GENERATORS
    rally = 0.10,
    clash = 0.10,
    advance = 0.15,
    holy_bolt = 0.10,
    brandish = 0.10,
    
    -- MOBILITY
    shield_charge = 0.40,
}

-- =====================================================
-- USE_ABILITY FUNCTION (Druid Pattern)
-- Centralized spell casting with proper target handling
-- This prevents multiple spells from fighting over movement
-- =====================================================
local function use_ability(spell_name, spell, spell_target, delay_after_cast)
    local debug_enabled = safe_get_menu_element(menu.menu_elements.enable_debug, false)
    
    -- Check if spell is enabled
    if not spell.menu_elements or not spell.menu_elements.main_boolean then
        -- Self-cast spells without main_boolean (shouldn't happen)
        if debug_enabled then dbg(spell_name .. ": no main_boolean, trying logics()") end
        if spell.logics() then
            return true
        end
        return false
    end
    
    if not spell.menu_elements.main_boolean:get() then
        -- Don't spam this - it's expected for disabled spells
        return false
    end
    
    -- For targeted spells, we need a valid target
    -- Self-cast spells (auras, consecration, etc.) handle nil target internally
    local is_targeted_spell = spell.menu_elements.targeting_mode ~= nil
    
    if is_targeted_spell then
        -- Targeted spell - MUST have a target to proceed
        if not spell_target then
            if debug_enabled then dbg(spell_name .. ": targeted spell but no target") end
            return false
        end
        
        -- Validate target
        if spell_target:is_dead() or spell_target:is_immune() or spell_target:is_untargetable() then
            if debug_enabled then dbg(spell_name .. ": target is dead/immune/untargetable") end
            return false
        end
        
        -- Call logics with target
        if debug_enabled then dbg(spell_name .. ": calling logics with target") end
        
        if type(spell.logics) ~= "function" then
            if debug_enabled then dbg(spell_name .. ": logics is not a function") end
            return false
        end
        
        -- SAFE CALL: Wrap spell logic in pcall to prevent script crash on single spell error
        local ok, success = pcall(spell.logics, spell_target)
        if ok and success == true then
            return true
        elseif not ok then
            if debug_enabled then dbg(spell_name .. " ERROR: " .. tostring(success)) end
        end
    else
        -- Self-cast spell (auras, consecration, etc.)
        -- These don't need a target - call logics without target
        if debug_enabled then dbg(spell_name .. ": self-cast, calling logics") end
        
        if type(spell.logics) ~= "function" then
            if debug_enabled then dbg(spell_name .. ": logics is not a function") end
            return false
        end
        
        -- SAFE CALL: Wrap spell logic in pcall
        local ok, success = pcall(spell.logics)
        if ok and success == true then
            return true
        elseif not ok then
            if debug_enabled then dbg(spell_name .. " ERROR: " .. tostring(success)) end
        end
    end
    
    return false
end

safe_on_update(function()
    local debug_enabled = false
    if menu and menu.menu_elements then
        debug_enabled = safe_get_menu_element(menu.menu_elements.enable_debug, false)
    end
    
    if not menu or not menu.menu_elements or not safe_get_menu_element(menu.menu_elements.main_boolean, false) then
        return
    end

    -- Sync global flags from menu so gameplay reacts immediately to UI changes
    update_global_flags_from_menu()

    -- Check orbwalker mode without forcing it (match reference repo behaviour)
    local current_orb_mode = orb_mode.none
    if orbwalker and orbwalker.get_orb_mode then
        local ok_mode, mode_val = pcall(function() return orbwalker.get_orb_mode() end)
        if ok_mode then
            current_orb_mode = mode_val
        end
    end

    -- Debug: Log orb mode periodically
    if debug_enabled then
        local now = my_utility.safe_get_time()
        if not _G.PaladinRotation.debug.orb_mode_time or (now - _G.PaladinRotation.debug.orb_mode_time) > 2.0 then
            _G.PaladinRotation.debug.orb_mode_time = now
            local mode_str = "unknown"
            if current_orb_mode == orb_mode.none then mode_str = "none"
            elseif current_orb_mode == orb_mode.pvp then mode_str = "pvp"
            elseif current_orb_mode == orb_mode.clear then mode_str = "clear"
            elseif current_orb_mode == orb_mode.flee then mode_str = "flee"
            end
            dbg("Orb Mode: " .. mode_str .. " (raw: " .. tostring(current_orb_mode) .. ")")
        end
    end

    -- CRITICAL FIX: Only run rotation if Orbwalker is active OR Auto Play is enabled
    -- This prevents the script from casting spells when the user is just standing still
    if current_orb_mode == orb_mode.none and not my_utility.is_auto_play_enabled() then
        return
    end

    local current_time = my_utility.safe_get_time()
    if current_time < cast_end_time then
        return
    end

    -- Use is_action_allowed for mount/buff checks (like sorc/barb)
    if not my_utility.is_action_allowed() then
        if debug_enabled then dbg("is_action_allowed returned false") end
        return
    end

    local player = get_local_player()
    if not player then return end
    
    -- Perform class check once when player is available
    if not is_paladin_checked then
        local character_id = player:get_character_class_id() or -1
        -- Paladin/Spiritborn is class ID 7
        is_paladin_class = (character_id == 7)
        if not is_paladin_class and console and console.print then
            console.print("Paladin_Rotation: unexpected class_id=" .. tostring(character_id) .. " (expected 7); continuing load for debugging")
        end
        is_paladin_checked = true
    end

    local player_position = player:get_position()

    -- =====================================================
    -- TARGETING RANGE (SCAN RADIUS)
    -- This is the maximum range to search for potential targets
    -- Individual spells have their own cast_range which determines
    -- if they can cast or need to move toward the target
    -- =====================================================
    local melee_range = my_utility.get_melee_range()
    local scan_radius = safe_get_menu_element(menu.menu_elements.scan_radius, 15)
    local scan_refresh_rate = safe_get_menu_element(menu.menu_elements.scan_refresh_rate, 0.2)
    
    -- DRUID-STYLE TARGETING: Evaluate ALL target types once per tick (throttled)
    -- Reuse the last evaluation if within refresh window and ranges unchanged
    local should_refresh_targets = false
    if not targets_cache.data then
        should_refresh_targets = true
    else
        if (current_time - targets_cache.time) >= scan_refresh_rate then
            should_refresh_targets = true
        end
        if targets_cache.melee_range ~= melee_range or targets_cache.scan_radius ~= scan_radius then
            should_refresh_targets = true
        end
    end

    if should_refresh_targets then
        targets_cache.data = evaluate_all_targets(player_position, melee_range, scan_radius)
        targets_cache.time = current_time
        targets_cache.melee_range = melee_range
        targets_cache.scan_radius = scan_radius
        
        -- Update global valid enemies list for other modules to use
        if targets_cache.data and targets_cache.data.valid_enemies then
            _G.PaladinRotation.valid_enemies = targets_cache.data.valid_enemies
        else
            _G.PaladinRotation.valid_enemies = {}
        end
    end

    local evaluated_targets = targets_cache.data or {
        valid_enemies = {},
        closest = nil,
        best_melee = nil,
        best_ranged = nil,
        best_cursor = nil
    }
    
    -- If no targets at all, exit early and update global state
    if not evaluated_targets.closest and not evaluated_targets.best_melee and not evaluated_targets.best_ranged then
        -- Update global state for Looteer coordination
        _G.PaladinRotation.in_combat = false
        _G.PaladinRotation.is_casting = false
        _G.PaladinRotation.current_target_id = nil
        if debug_enabled then
            -- Only log this occasionally to avoid spam
            if not _G.PaladinRotation.debug.no_targets_time or (current_time - _G.PaladinRotation.debug.no_targets_time) > 2.0 then
                _G.PaladinRotation.debug.no_targets_time = current_time
                dbg("No valid targets found - check elevation/visibility settings")
            end
        end
        return
    end
    
    -- Debug: Log when targets ARE found
    if debug_enabled then
        if not _G.PaladinRotation.debug.targets_found_time or (current_time - _G.PaladinRotation.debug.targets_found_time) > 2.0 then
            _G.PaladinRotation.debug.targets_found_time = current_time
            local closest_name = evaluated_targets.closest and evaluated_targets.closest:get_skin_name() or "nil"
            dbg("Targets found! Closest: " .. closest_name)
        end
    end
    
    -- UPDATE GLOBAL STATE: We have combat targets
    _G.PaladinRotation.in_combat = true
    _G.PaladinRotation.is_casting = (current_time < cast_end_time)
    
    -- Weighted targeting (optional): prefer clustered/high-value targets when enabled
    local weighted_target = nil
    if safe_get_menu_element(menu.menu_elements.weighted_targeting_enabled, false) then
        local min_targets = safe_get_menu_element(menu.menu_elements.min_targets, 1)
        local comparison_radius = safe_get_menu_element(menu.menu_elements.comparison_radius, 3.0)
        local refresh_rate = safe_get_menu_element(menu.menu_elements.scan_refresh_rate, 0.2)
        local boss_weight = safe_get_menu_element(menu.menu_elements.boss_weight, 50)
        local elite_weight = safe_get_menu_element(menu.menu_elements.elite_weight, 10)
        local champion_weight = safe_get_menu_element(menu.menu_elements.champion_weight, 15)
        local any_weight = safe_get_menu_element(menu.menu_elements.any_weight, 2)

        local custom_buff_weights = safe_get_menu_element(menu.menu_elements.custom_buff_weights_enabled, false)
        local damage_resistance_provider_weight = custom_buff_weights and safe_get_menu_element(menu.menu_elements.damage_resistance_provider_weight, 30) or 0
        local damage_resistance_receiver_penalty = custom_buff_weights and safe_get_menu_element(menu.menu_elements.damage_resistance_receiver_penalty, 5) or 0
        local horde_objective_weight = custom_buff_weights and safe_get_menu_element(menu.menu_elements.horde_objective_weight, 50) or 0
        local vulnerable_debuff_weight = custom_buff_weights and safe_get_menu_element(menu.menu_elements.vulnerable_debuff_weight, 1) or 0

        local custom_enemy_sliders = safe_get_menu_element(menu.menu_elements.custom_enemy_sliders_enabled, false)
        local normal_target_count = custom_enemy_sliders and safe_get_menu_element(menu.menu_elements.normal_target_count, 1) or 1
        local champion_target_count = custom_enemy_sliders and safe_get_menu_element(menu.menu_elements.champion_target_count, 5) or 5
        local elite_target_count = custom_enemy_sliders and safe_get_menu_element(menu.menu_elements.elite_target_count, 5) or 5
        local boss_target_count = custom_enemy_sliders and safe_get_menu_element(menu.menu_elements.boss_target_count, 5) or 5

        local cluster_threshold = min_targets
        local wt_debug = safe_get_menu_element(menu.menu_elements.weighted_targeting_debug, false)
        local floor_height_threshold = safe_get_menu_element(menu.menu_elements.floor_height_threshold, 5.0)

        -- OPTIMIZATION: Use pre-filtered list from evaluate_all_targets to avoid double scanning
        local pre_filtered_units = {}
        if evaluated_targets.valid_enemies then
            for _, data in ipairs(evaluated_targets.valid_enemies) do
                table.insert(pre_filtered_units, data.unit)
            end
        end

        weighted_target = my_target_selector.get_weighted_target(
            player_position,
            scan_radius,
            min_targets,
            comparison_radius,
            boss_weight,
            elite_weight,
            champion_weight,
            any_weight,
            refresh_rate,
            damage_resistance_provider_weight,
            damage_resistance_receiver_penalty,
            horde_objective_weight,
            vulnerable_debuff_weight,
            cluster_threshold,
            normal_target_count,
            champion_target_count,
            elite_target_count,
            boss_target_count,
            wt_debug,
            floor_height_threshold,
            pre_filtered_units
        )
    end

    -- Inject weighted target into evaluated targets so per-mode selection can prefer it
    if weighted_target then
        evaluated_targets.weighted = weighted_target
        evaluated_targets.best_ranged = weighted_target
        evaluated_targets.best_melee = evaluated_targets.best_melee or weighted_target
    end

    -- Default target for spells without per-spell targeting_mode (uses weighted first, then closest for melee safety)
    local default_target = weighted_target or evaluated_targets.closest or evaluated_targets.best_melee
    
    -- Track current target for Looteer coordination
    if default_target then
        _G.PaladinRotation.current_target_id = default_target:get_id()
        local ok_name, tgt_name = pcall(function() return default_target:get_skin_name() end)
        _G.PaladinRotation.current_target_name = ok_name and tgt_name or "(unknown)"
    end

    -- Get equipped spells for spell casting logic
    -- OPTIMIZATION: Cache equipped spells to avoid calling get_equipped_spell_ids() every frame
    -- This matches the optimization pattern used for target scanning
    if not _G.PaladinRotation.equipped_spells_cache or (current_time - (_G.PaladinRotation.equipped_spells_time or 0)) > 2.0 then
        _G.PaladinRotation.equipped_spells_cache = get_equipped_spell_ids() or {}
        _G.PaladinRotation.equipped_spells_time = current_time
        
        -- Rebuild lookup table when cache updates
        _G.PaladinRotation.equipped_lookup = {}
        for _, spell_id in ipairs(_G.PaladinRotation.equipped_spells_cache) do
            _G.PaladinRotation.equipped_lookup[spell_id] = true
        end
    end
    
    local equipped_spells = _G.PaladinRotation.equipped_spells_cache
    local equipped_lookup = _G.PaladinRotation.equipped_lookup or {}

    -- Debug: Print equipped spell IDs once
    if debug_enabled then
        if not _G.PaladinRotation.debug.equipped_printed or (current_time - _G.PaladinRotation.debug.equipped_printed) > 10.0 then
            _G.PaladinRotation.debug.equipped_printed = current_time
            local ids_str = ""
            for i, sid in ipairs(equipped_spells) do
                ids_str = ids_str .. tostring(sid) .. ", "
            end
            dbg("Equipped spell IDs: " .. ids_str)
        end
    end

    -- If we cannot read equipped spells (new class IDs, API quirks), auto-bypass equip check
    local bypass_equipped = menu.menu_elements.bypass_equipped_check:get()
    if (next(equipped_lookup) == nil) and (not bypass_equipped) then
        bypass_equipped = true
        if debug_enabled then
            dbg("Equipped spell list empty - auto-enabling bypass to allow casting")
        end
    end

    -- Loop through spells in priority order defined in spell_priority.lua
    for _, spell_name in ipairs(spell_priority) do
        local spell = spells[spell_name]
        local spell_equipped = spell and spell_data[spell_name] and spell_data[spell_name].spell_id and equipped_lookup[spell_data[spell_name].spell_id]
        local should_process = spell_equipped or (bypass_equipped and spell and spell_data[spell_name])
        
        if should_process then
            if debug_enabled and spell_data[spell_name] then
                if not spell_equipped then
                    _G.PaladinRotation.debug.last_equip = _G.PaladinRotation.debug.last_equip or {}
                    if not _G.PaladinRotation.debug.last_equip[spell_name] or (current_time - _G.PaladinRotation.debug.last_equip[spell_name]) > 2.0 then
                        _G.PaladinRotation.debug.last_equip[spell_name] = current_time
                        dbg(spell_name .. " not equipped (spell_id: " .. tostring(spell_data[spell_name].spell_id) .. ")" .. (bypass_equipped and " [BYPASSED]" or ""))
                    end
                end
            end
            
            -- Check internal cooldown for this spell
            local internal_cooldown = spell_internal_cooldowns[spell_name] or 0
            if internal_cooldown > 0 then
                local last_cast_time = spell_last_cast_times[spell_name] or 0
                local time_since_last_cast = current_time - last_cast_time
                if time_since_last_cast < internal_cooldown then
                    goto continue
                end
            end
            
            -- DRUID-STYLE PER-SPELL TARGETING:
            local spell_target = nil
            if spell.menu_elements and spell.menu_elements.targeting_mode then
                local targeting_mode = spell.menu_elements.targeting_mode:get()
                spell_target = my_utility.get_target_by_mode(targeting_mode, evaluated_targets)
            else
                spell_target = default_target
            end
            
            -- TARGET STICKINESS: If we have a sticky target, prefer it if valid
            if sticky_target and (current_time - sticky_target_time) < sticky_duration then
                if not sticky_target:is_dead() and not sticky_target:is_immune() and not sticky_target:is_untargetable() then
                    if spell.menu_elements and spell.menu_elements.targeting_mode then
                        spell_target = sticky_target
                    end
                else
                    sticky_target = nil
                end
            end
            
            -- Use the centralized use_ability function
            local cast_successful = use_ability(spell_name, spell, spell_target, my_utility.spell_delays.regular_cast)

            if cast_successful then
                -- Animation lock
                cast_end_time = current_time + my_utility.spell_delays.regular_cast
                
                -- Update global state for Looteer coordination
                _G.PaladinRotation.last_cast_time = current_time
                _G.PaladinRotation.is_casting = true
                
                -- Update internal cooldown tracking
                spell_last_cast_times[spell_name] = current_time
                
                -- Track for rotation debugging
                last_spell_cast_name = spell_name
                spell_cast_counts[spell_name] = (spell_cast_counts[spell_name] or 0) + 1
                
                -- Update sticky target
                if spell_target then
                    sticky_target = spell_target
                    sticky_target_time = current_time
                    last_cast_target = spell_target
                end
                
                if debug_enabled then
                    dbg("Cast " .. spell_name .. " (count " .. spell_cast_counts[spell_name] .. ")")
                end
                return
            end
            
            ::continue::
        end
    end
    
    -- MOVEMENT HANDLING: Auto Play / Botting Support
    -- If auto-play is enabled and we haven't cast a spell (and aren't in danger), move to target
    if my_utility.is_auto_play_enabled() then
        local player_pos = player:get_position()
        local is_dangerous = false
        if evade and evade.is_dangerous_position then
            is_dangerous = evade.is_dangerous_position(player_pos)
        end
        
        if not is_dangerous then
            -- Use the default target (weighted or closest)
            local target = default_target
            if target then
                local target_pos = target:get_position()
                if target_pos then
                    -- Move to within 4 yards of the target (melee range)
                    -- get_extended: from target_pos, extend towards player_pos by 4.0 units
                    local move_pos = target_pos:get_extended(player_pos, 4.0)
                    my_utility.move_to_target(move_pos, target:get_id())
                end
            end
        end
    end
end)

-- Lightweight debug overlay (toggle with Enable Debug)
safe_on_render(function()
    if not safe_get_menu_element(menu.menu_elements.enable_debug, false) then
        return
    end

    local player = get_local_player()
    if not player then return end
    local player_pos = player:get_position()
    local pos2d = graphics.w2s(player_pos)
    if not pos2d or pos2d:is_zero() then return end

    local function make_vec2_safe(px, py)
        if vec2 then return vec2(px, py) end
        return nil
    end

    -- Draw ranges
    local scan_radius = safe_get_menu_element(menu.menu_elements.scan_radius, 15)
    graphics.circle_3d(player_pos, scan_radius, color_white(85), 2.5, 144)
    
    local melee_range = my_utility.get_melee_range()
    graphics.circle_3d(player_pos, melee_range, color_white(85), 2.5, 144)

    -- Draw targets
    local targets = targets_cache.data
    if targets then
        local function draw_target(unit, label, col)
            if unit then
                local pos = unit:get_position()
                if pos then
                    graphics.circle_3d(pos, 1.0, col, 2.0)
                    local p2d = graphics.w2s(pos)
                    if p2d and not p2d:is_zero() then
                        graphics.line(pos2d, p2d, col, 2.0)
                        graphics.text_2d(label, p2d, 16, col)
                    end
                end
            end
        end

        draw_target(targets.best_melee, "Melee", color_green(200))
        draw_target(targets.best_ranged, "Ranged", color_red(200))
        draw_target(targets.best_cursor, "Cursor", color_orange(200))
    end

    local lines = {}
    local mode = "nil"
    if orbwalker and orbwalker.get_orb_mode then
        local ok, m = pcall(function() return orbwalker.get_orb_mode() end)
        if ok then
            if orb_mode then
                if m == orb_mode.none then mode = "none"
                elseif m == orb_mode.pvp then mode = "pvp"
                elseif m == orb_mode.clear then mode = "clear"
                elseif m == orb_mode.flee then mode = "flee"
                else mode = tostring(m)
                end
            else
                mode = tostring(m)
            end
        end
    end

    table.insert(lines, "Orbwalker: " .. mode)
    table.insert(lines, "Last Spell: " .. tostring(last_spell_cast_name or "-"))
    if _G.PaladinRotation then
        table.insert(lines, "Target ID: " .. tostring(_G.PaladinRotation.current_target_id or "-"))
        table.insert(lines, "Target Name: " .. tostring(_G.PaladinRotation.current_target_name or "-"))
    end

    local x = pos2d.x + 40
    local y = pos2d.y - 120
    local line_height = 16
    for i, text in ipairs(lines) do
        local p = make_vec2_safe(x, y + (i - 1) * line_height)
        if p then
            graphics.text_2d(text, p, 16, color_white(220))
        end
    end
end)

if console and type(console.print) == "function" then
    console.print("Paladin_Rotation | Version 2.0 (Spell Rotation Fairness System)")
end
