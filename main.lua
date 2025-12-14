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
-- Paladin Class ID: 7 (new class added in Season 11 / Lord of Hatred expansion)
-- Note: If Paladin doesn't work with ID 7, try uncommenting the check below
-- Class IDs: Sorcerer=0, Barbarian=1, Rogue=3, Druid=5, Necromancer=6, Spiritborn/Paladin=7
local local_player = get_local_player()
if not local_player then
    return
end

local character_id = local_player:get_character_class_id()
local is_paladin = character_id == 7 -- Paladin class ID
-- Uncomment below to restrict plugin to Paladin only:
-- if not is_paladin then
--     return
-- end

-- Orbwalker settings (like druid/barb) - take control of movement
-- These MUST be called unconditionally at the top level, before any logic
-- set_block_movement(true): We handle all movement in spell logics, not orbwalker
-- set_clear_toggle(true): Allow the clear mode toggle to work
orbwalker.set_block_movement(true)
orbwalker.set_clear_toggle(true)

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local spell_priority = require("spell_priority")
local menu = require("menu")
local my_target_selector = require("my_utility/my_target_selector")

-- GLOBAL STATE FOR LOOTEER COORDINATION
-- Looteer checks this before looting to avoid conflicts with combat
-- When in_combat=true or is_casting=true, Looteer should defer looting
_G.PaladinRotation = {
    in_combat = false,      -- True when we have valid combat targets
    is_casting = false,     -- True when we're in cast animation
    last_cast_time = 0,     -- Time of last successful cast
    current_target_id = nil -- ID of current target for coordination
}

local function safe_on_render_menu(cb)
    if type(_G.safe_on_render_menu) == "function" then
        return _G.safe_on_render_menu(cb)
    end
    if type(_G.on_render_menu) == "function" then
        return _G.on_render_menu(cb)
    end
    return false
end

local function safe_on_update(cb)
    if type(_G.safe_on_update) == "function" then
        return _G.safe_on_update(cb)
    end
    if type(_G.on_update) == "function" then
        return _G.on_update(cb)
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

local function safe_get_menu_element(element, fallback)
    if element and type(element.get) == "function" then
        return element:get()
    end
    return fallback
end

local function dbg(msg)
    local enabled = safe_get_menu_element(menu.menu_elements.enable_debug, false)
    if enabled and console and type(console.print) == "function" then
        console.print("[Paladin_Rotation] " .. msg)
    end
end

local function get_best_target(max_range, cluster_radius, prefer_elites)
    local player = get_local_player()
    if not player then return nil, 0, false end

    local player_pos = player:get_position()
    local enemies = actors_manager.get_enemy_npcs()

    local max_range_sqr = max_range * max_range
    local cluster_radius_sqr = (cluster_radius or 6.0)
    cluster_radius_sqr = cluster_radius_sqr * cluster_radius_sqr

    local count = 0
    local has_boss_like = false

    local candidates = {}
    for _, e in ipairs(enemies) do
        if e and e:is_enemy() then
            local pos = e:get_position()
            if pos then
                local d = pos:squared_dist_to_ignore_z(player_pos)
                if d <= max_range_sqr then
                    count = count + 1
                    if e:is_boss() or e:is_champion() then
                        has_boss_like = true
                    end
                    table.insert(candidates, { unit = e, pos = pos, dist_sqr = d })
                end
            end
        end
    end

    if #candidates == 0 then
        return nil, 0, false
    end

    local best = nil
    local best_score = -math.huge

    for i = 1, #candidates do
        local c = candidates[i]
        local u = c.unit
        local score = 0

        -- Prefer higher value targets
        if u:is_boss() then
            score = score + 5000
        elseif u:is_champion() then
            score = score + 2500
        elseif u:is_elite() then
            score = score + 1000
        end

        -- Cluster score (how many enemies are near this target)
        local cluster = 0
        for j = 1, #candidates do
            if i ~= j then
                local d2 = candidates[j].pos:squared_dist_to_ignore_z(c.pos)
                if d2 <= cluster_radius_sqr then
                    cluster = cluster + 1
                end
            end
        end
        score = score + (cluster * 50)

        -- Distance bias (slight)
        score = score - (c.dist_sqr * 0.01)

        -- If enabled, devalue normal mobs so we more consistently snap to elites
        if prefer_elites and (not u:is_elite()) and (not u:is_champion()) and (not u:is_boss()) then
            score = score - 300
        end

        if score > best_score then
            best_score = score
            best = u
        end
    end

    return best, count, has_boss_like
end

-- Evaluate all target types for the Druid-style per-spell targeting system
-- This runs once per update tick and returns all possible targets
-- Spells then pick the appropriate target based on their targeting_mode setting
local function evaluate_all_targets(player_pos, melee_range, max_range)
    -- Use target_selector.get_near_target_list() for pre-filtered list by range
    -- This matches reference repos (Druid, Spiritborn) and is more efficient
    local enemies = target_selector.get_near_target_list(player_pos, max_range) or {}
    
    -- Result table with all target types
    local targets = {
        best_ranged = nil,           -- 0: Best weighted for ranged
        best_ranged_visible = nil,   -- 1: Same with visibility check
        best_melee = nil,            -- 2: Best weighted for melee
        best_melee_visible = nil,    -- 3: Same with visibility check
        closest = nil,               -- 4: Closest by distance
        closest_visible = nil,       -- 5: Closest with visibility check
        best_cursor = nil,           -- 6: Best weighted near cursor
        closest_cursor = nil,        -- 7: Closest to cursor
    }
    
    local melee_range_sqr = melee_range * melee_range
    local max_range_sqr = max_range * max_range
    local cursor_pos = get_cursor_position()
    local cursor_range_sqr = 10.0 * 10.0  -- 10 unit radius around cursor
    
    -- Get weights from menu (matching reference repos: Druid/Spiritborn)
    -- Default values: normal=2, elite=10, champion=15, boss=50
    local normal_weight = safe_get_menu_element(menu.menu_elements.any_weight, 2)
    local elite_weight = safe_get_menu_element(menu.menu_elements.elite_weight, 10)
    local champion_weight = safe_get_menu_element(menu.menu_elements.champion_weight, 15)
    local boss_weight = safe_get_menu_element(menu.menu_elements.boss_weight, 50)
    local comparison_radius = safe_get_menu_element(menu.menu_elements.comparison_radius, 3.0)
    local comparison_radius_sqr = comparison_radius * comparison_radius
    
    -- Collect valid enemies with scoring data
    local melee_candidates = {}
    local ranged_candidates = {}
    local cursor_candidates = {}
    local closest_dist = math.huge
    local closest_unit = nil
    local closest_visible_dist = math.huge
    local closest_visible_unit = nil
    
    -- First pass: collect all valid enemies with positions
    local valid_enemies = {}
    for _, e in ipairs(enemies) do
        if e and e:is_enemy() then
            if e:is_dead() or e:is_immune() or e:is_untargetable() then
                goto continue_collect
            end
            local pos = e:get_position()
            if not pos then goto continue_collect end
            local dist_sqr = pos:squared_dist_to_ignore_z(player_pos)
            if dist_sqr > max_range_sqr then goto continue_collect end
            
            table.insert(valid_enemies, {unit = e, pos = pos, dist_sqr = dist_sqr})
            ::continue_collect::
        end
    end
    
    -- Second pass: calculate scores with cluster weighting (like Druid/Spiritborn)
    for _, data in ipairs(valid_enemies) do
        local e = data.unit
        local pos = data.pos
        local dist_sqr = data.dist_sqr
        
        -- Check visibility (no wall collision)
        local is_visible = true
        if target_selector and target_selector.is_wall_collision then
            is_visible = not target_selector.is_wall_collision(player_pos, e, 1.0)
        end
        
        -- Calculate base score using menu weights (matching reference repos)
        local score = normal_weight  -- Start with normal weight as base
        if e:is_boss() then
            score = boss_weight
        elseif e:is_champion() then
            score = champion_weight
        elseif e:is_elite() then
            score = elite_weight
        end
        
        -- Add vulnerable bonus (like reference repos)
        if e:is_vulnerable() then
            score = score + 100  -- High priority for vulnerable targets
        end
        
        -- Add cluster bonus: count nearby enemies and add their weights
        -- This matches Druid/Spiritborn pattern of evaluating clusters
        for _, other in ipairs(valid_enemies) do
            if other.unit ~= e then
                local cluster_dist_sqr = pos:squared_dist_to_ignore_z(other.pos)
                if cluster_dist_sqr <= comparison_radius_sqr then
                    -- Add weight based on nearby enemy type
                    if other.unit:is_boss() then
                        score = score + boss_weight
                    elseif other.unit:is_champion() then
                        score = score + champion_weight
                    elseif other.unit:is_elite() then
                        score = score + elite_weight
                    else
                        score = score + normal_weight
                    end
                end
            end
        end
        
        -- Distance penalty (slight) - closer targets get slight priority
        score = score - (dist_sqr * 0.01)
        
        -- Track closest targets (now guaranteed within max_range)
        if dist_sqr < closest_dist then
            closest_dist = dist_sqr
            closest_unit = e
        end
        if is_visible and dist_sqr < closest_visible_dist then
            closest_visible_dist = dist_sqr
            closest_visible_unit = e
        end
        
        -- Categorize by range
        if dist_sqr <= melee_range_sqr then
            table.insert(melee_candidates, {unit = e, score = score, visible = is_visible})
        end
        -- All enemies are already within max_range, so add to ranged
        table.insert(ranged_candidates, {unit = e, score = score, visible = is_visible})
        
        -- Cursor-based candidates (still within max_range)
        if cursor_pos then
            local cursor_dist_sqr = pos:squared_dist_to_ignore_z(cursor_pos)
            if cursor_dist_sqr <= cursor_range_sqr then
                table.insert(cursor_candidates, {unit = e, score = score, cursor_dist = cursor_dist_sqr})
            end
        end
    end
    
    -- Set closest targets (modes 4, 5)
    targets.closest = closest_unit
    targets.closest_visible = closest_visible_unit
    
    -- Find best melee targets (modes 2, 3)
    local best_melee_score = -math.huge
    local best_melee_visible_score = -math.huge
    for _, c in ipairs(melee_candidates) do
        if c.score > best_melee_score then
            best_melee_score = c.score
            targets.best_melee = c.unit
        end
        if c.visible and c.score > best_melee_visible_score then
            best_melee_visible_score = c.score
            targets.best_melee_visible = c.unit
        end
    end
    
    -- Find best ranged targets (modes 0, 1)
    local best_ranged_score = -math.huge
    local best_ranged_visible_score = -math.huge
    for _, c in ipairs(ranged_candidates) do
        if c.score > best_ranged_score then
            best_ranged_score = c.score
            targets.best_ranged = c.unit
        end
        if c.visible and c.score > best_ranged_visible_score then
            best_ranged_visible_score = c.score
            targets.best_ranged_visible = c.unit
        end
    end
    
    -- Find cursor targets (modes 6, 7)
    local best_cursor_score = -math.huge
    local closest_cursor_dist = math.huge
    for _, c in ipairs(cursor_candidates) do
        if c.score > best_cursor_score then
            best_cursor_score = c.score
            targets.best_cursor = c.unit
        end
        if c.cursor_dist < closest_cursor_dist then
            closest_cursor_dist = c.cursor_dist
            targets.closest_cursor = c.unit
        end
    end
    
    -- Fallbacks: if melee targets are nil, use ranged or closest
    if not targets.best_melee then targets.best_melee = targets.best_ranged or targets.closest end
    if not targets.best_melee_visible then targets.best_melee_visible = targets.best_ranged_visible or targets.closest_visible end
    
    return targets
end

-- Get target for a spell based on its targeting_mode menu element
local function get_spell_target(spell, evaluated_targets)
    if not spell or not spell.menu_elements then
        return evaluated_targets.closest or evaluated_targets.best_melee
    end
    
    -- Check if spell has targeting_mode menu element
    if spell.menu_elements.targeting_mode then
        local mode = spell.menu_elements.targeting_mode:get()
        return my_utility.get_target_by_mode(mode, evaluated_targets)
    end
    
    -- Default to closest for melee spells without targeting_mode
    return evaluated_targets.closest or evaluated_targets.best_melee
end

safe_on_render_menu(function()
    if not menu.menu_elements.main_tree:push("Paladin_Rotation") then
        return
    end

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
            -- Scan settings
            menu.menu_elements.scan_radius:render("Scan Radius", "Radius around character to scan for targets (1-30)")
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

    if menu.menu_elements.settings_tree:push("Settings") then
        -- Only show legacy targeting settings if weighted targeting is disabled
        if not menu.menu_elements.weighted_targeting_enabled:get() then
            menu.menu_elements.max_targeting_range:render("Max Targeting Range", "")
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
        
        -- Manual Play Mode (like barb)
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

-- TARGET STICKINESS: Prevent oscillation by sticking to a target for a minimum time
local sticky_target = nil
local sticky_target_time = 0.0
local sticky_duration = 0.75  -- Stay on same target for at least 0.75s
local last_cast_target = nil  -- Track target we last successfully cast at

-- Internal cooldowns (minimum time between casts of same spell)
-- These control how often each spell can be CHECKED for casting
-- Lower values = more frequent checks = higher priority in practice
--
-- META OPTIMIZATION (Hammerdin from maxroll.gg):
-- - Core spam (blessed_hammer) has SHORT ICD so it casts frequently
-- - Arbiter triggers (falling_star, condemn) have SHORT ICD for max uptime
-- - Rally used often for move speed buff
-- - Generators have SHORT ICD but their logics() blocks when Faith is high
local spell_internal_cooldowns = {
    -- CORE SPAM - Very short ICD for maximum spam rate
    -- META: "Spam Blessed Hammer to deal damage" - minimal ICD
    blessed_hammer = 0.05,  -- Primary spam skill - cast as fast as possible (was 0.10)
    
    -- ALTERNATIVE CORE SPENDERS - Slightly longer to not compete with main
    blessed_shield = 0.20,  -- Higher cost, use when ricochet value
    zeal = 0.15,            -- Fast melee combo
    divine_lance = 0.20,    -- Mobility spender
    
    -- ULTIMATES - Short ICD, game handles actual cooldown
    -- We want these to cast IMMEDIATELY when available
    arbiter_of_justice = 0.25,
    heavens_fury = 0.25,
    zenith = 0.25,
    
    -- AURAS - Moderate ICD, buff duration handled in spell logic
    -- Check every 0.5s is plenty for buff maintenance
    fanaticism_aura = 0.50,
    defiance_aura = 0.50,
    holy_light_aura = 0.50,
    
    -- BURST COOLDOWNS - These have game cooldowns (12-18s)
    -- ARBITER TRIGGERS (falling_star, condemn) - VERY LOW ICD for max uptime!
    -- META: "Use Falling Star OR Condemn every few seconds to stay in Arbiter form"
    -- These are CRITICAL for Hammerdin to stay in Arbiter form
    falling_star = 0.10,        -- ARBITER TRIGGER - react VERY fast (was 0.20)
    spear_of_the_heavens = 0.25, -- Ranged burst (was 0.30)
    condemn = 0.10,             -- ARBITER TRIGGER - react VERY fast (was 0.20)
    consecration = 0.35,        -- Ground effect, less urgent (was 0.40)
    
    -- GENERATORS - Short ICD, but logics() has resource threshold
    -- Rally moved to buff tier - very short ICD for maximum uptime
    rally = 0.10,      -- META: "Use Rally as often as possible!" Very short ICD (was 0.15)
    clash = 0.12,      -- Shield bash - fast generator (was 0.15)
    advance = 0.20,    -- Gap closer + gen (was 0.25)
    holy_bolt = 0.12,  -- Ranged filler (was 0.15)
    brandish = 0.12,   -- Melee arc filler (was 0.15)
    
    -- MOBILITY - Moderate ICD, positioning not DPS
    shield_charge = 0.50,
}

-- =====================================================
-- USE_ABILITY FUNCTION (Druid Pattern)
-- Centralized spell casting with proper target handling
-- This prevents multiple spells from fighting over movement
-- =====================================================
local function use_ability(spell_name, spell, spell_target, delay_after_cast)
    -- Check if spell is enabled
    if not spell.menu_elements or not spell.menu_elements.main_boolean then
        -- Self-cast spells without main_boolean (shouldn't happen)
        if spell.logics() then
            return true
        end
        return false
    end
    
    if not spell.menu_elements.main_boolean:get() then
        return false
    end
    
    -- For targeted spells, we need a valid target
    -- Self-cast spells (auras, consecration, etc.) handle nil target internally
    local is_targeted_spell = spell.menu_elements.targeting_mode ~= nil
    
    if is_targeted_spell then
        -- Targeted spell - MUST have a target to proceed
        if not spell_target then
            return false
        end
        
        -- Validate target
        if spell_target:is_dead() or spell_target:is_immune() or spell_target:is_untargetable() then
            return false
        end
        
        -- Call logics with target
        if spell.logics(spell_target) then
            return true
        end
    else
        -- Self-cast spell (auras, consecration, etc.)
        -- These don't need a target - call logics directly
        if spell.logics(spell_target) then
            return true
        end
    end
    
    return false
end

safe_on_update(function()
    if not safe_get_menu_element(menu.menu_elements.main_boolean, false) then
        return
    end

    -- Check orbwalker mode (matching Druid pattern)
    -- orbwalker mode check is also in is_spell_allowed() but we check here for early exit
    local current_orb_mode = orbwalker.get_orb_mode()
    if current_orb_mode == orb_mode.none then
        -- Allow if auto_play is active
        if not my_utility.is_auto_play_enabled() then
            return
        end
    end

    local current_time = get_time_since_inject()
    if current_time < cast_end_time then
        return
    end

    -- Use is_action_allowed for mount/buff checks (like sorc/barb)
    if not my_utility.is_action_allowed() then
        return
    end

    local player = get_local_player()
    if not player then return end
    local player_position = player:get_position()

    -- Get melee and max range settings
    local melee_range = my_utility.get_melee_range()
    local max_range = safe_get_menu_element(menu.menu_elements.max_targeting_range, 30)
    
    -- DRUID-STYLE TARGETING: Evaluate ALL target types once per tick
    -- Each spell picks its target based on its targeting_mode menu setting
    local evaluated_targets = evaluate_all_targets(player_position, melee_range, max_range)
    
    -- If no targets at all, exit early and update global state
    if not evaluated_targets.closest and not evaluated_targets.best_melee and not evaluated_targets.best_ranged then
        -- Update global state for Looteer coordination
        _G.PaladinRotation.in_combat = false
        _G.PaladinRotation.is_casting = false
        _G.PaladinRotation.current_target_id = nil
        return
    end
    
    -- UPDATE GLOBAL STATE: We have combat targets
    _G.PaladinRotation.in_combat = true
    _G.PaladinRotation.is_casting = (current_time < cast_end_time)
    
    -- Default target for spells without per-spell targeting_mode (uses closest for melee safety)
    local default_target = evaluated_targets.closest or evaluated_targets.best_melee
    
    -- Track current target for Looteer coordination
    if default_target then
        _G.PaladinRotation.current_target_id = default_target:get_id()
    end

    -- Get equipped spells for spell casting logic
    local equipped_spells = get_equipped_spell_ids() or {}

    -- Debug: Print equipped spell IDs once
    if menu.menu_elements.enable_debug:get() then
        if not _G.paladin_equipped_printed or (current_time - _G.paladin_equipped_printed) > 10.0 then
            _G.paladin_equipped_printed = current_time
            local ids_str = ""
            for i, sid in ipairs(equipped_spells) do
                ids_str = ids_str .. tostring(sid) .. ", "
            end
            dbg("Equipped spell IDs: " .. ids_str)
        end
    end

    -- Create a lookup table for equipped spells
    local equipped_lookup = {}
    for _, spell_id in ipairs(equipped_spells) do
        equipped_lookup[spell_id] = true
    end

    -- Loop through spells in priority order defined in spell_priority.lua
    local bypass_equipped = menu.menu_elements.bypass_equipped_check:get()
    
    -- Track if any spell requested movement this frame
    local move_requested = false
    local move_target_pos = nil
    
    for _, spell_name in ipairs(spell_priority) do
        local spell = spells[spell_name]
        -- Only process spells that are equipped (or bypass if debug enabled)
        local spell_equipped = spell and spell_data[spell_name] and spell_data[spell_name].spell_id and equipped_lookup[spell_data[spell_name].spell_id]
        local should_process = spell_equipped or (bypass_equipped and spell and spell_data[spell_name])
        
        if menu.menu_elements.enable_debug:get() and spell_data[spell_name] then
            if not spell_equipped then
                -- Only log once per 2 seconds to avoid spam
                _G.paladin_last_equip_debug = _G.paladin_last_equip_debug or {}
                if not _G.paladin_last_equip_debug[spell_name] or (current_time - _G.paladin_last_equip_debug[spell_name]) > 2.0 then
                    _G.paladin_last_equip_debug[spell_name] = current_time
                    dbg(spell_name .. " not equipped (spell_id: " .. tostring(spell_data[spell_name].spell_id) .. ")" .. (bypass_equipped and " [BYPASSED]" or ""))
                end
            end
        end
        
        if should_process then
            -- Check internal cooldown for this spell
            local internal_cooldown = spell_internal_cooldowns[spell_name] or 0
            if internal_cooldown > 0 then
                local last_cast_time = spell_last_cast_times[spell_name] or 0
                local time_since_last_cast = current_time - last_cast_time
                if time_since_last_cast < internal_cooldown then
                    -- Spell is still on internal cooldown, skip it
                    goto continue
                end
            end
            
            -- DRUID-STYLE PER-SPELL TARGETING:
            -- Get the appropriate target based on spell's targeting_mode menu setting
            -- If spell has targeting_mode, use it; otherwise use default_target
            local spell_target = nil
            if spell.menu_elements and spell.menu_elements.targeting_mode then
                local targeting_mode = spell.menu_elements.targeting_mode:get()
                spell_target = my_utility.get_target_by_mode(targeting_mode, evaluated_targets)
            else
                -- Self-cast spells (auras, etc.) don't need a target
                -- Targeted spells without targeting_mode use default (closest)
                spell_target = default_target
            end
            
            -- TARGET STICKINESS: If we have a sticky target, prefer it if valid
            if sticky_target and (current_time - sticky_target_time) < sticky_duration then
                -- Check if sticky target is still valid
                if not sticky_target:is_dead() and not sticky_target:is_immune() and not sticky_target:is_untargetable() then
                    -- Use sticky target for targeted spells
                    if spell.menu_elements and spell.menu_elements.targeting_mode then
                        spell_target = sticky_target
                    end
                else
                    -- Sticky target became invalid, clear it
                    sticky_target = nil
                end
            end
            
            -- Use the centralized use_ability function (Druid pattern)
            local cast_successful = use_ability(spell_name, spell, spell_target, my_utility.spell_delays.regular_cast)

            if cast_successful then
                -- Set cast_end_time to a SHORT animation lock (like Druid pattern)
                -- This prevents animation canceling, NOT spell rotation
                cast_end_time = current_time + my_utility.spell_delays.regular_cast
                
                -- Update global state for Looteer coordination
                _G.PaladinRotation.last_cast_time = current_time
                _G.PaladinRotation.is_casting = true
                
                -- Update internal cooldown tracking for this spell
                spell_last_cast_times[spell_name] = current_time
                
                -- Update sticky target on successful cast
                if spell_target then
                    sticky_target = spell_target
                    sticky_target_time = current_time
                    last_cast_target = spell_target
                end
                
                -- Clear move target since we just cast
                current_move_target = nil
                
                if menu.menu_elements.enable_debug:get() then
                    dbg("Cast " .. spell_name)
                end
                return
            end
            
            ::continue::
        end
    end
    
    -- MOVEMENT HANDLING: Removed from main.lua
    -- Movement is now handled INSIDE each spell's logics() function using the Druid pattern:
    -- 1. Spell checks if target is in range
    -- 2. If out of range: pathfinder.force_move_raw(target_pos) with move_delay
    -- 3. Return false (don't cast) and let next tick re-check
    -- This prevents oscillation by having ONE source of movement decisions per spell
end)

if console and type(console.print) == "function" then
    console.print("Paladin_Rotation | Version 1.9 (Targeting & Weighting Fix - Dec 2025)")
end
