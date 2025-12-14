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

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local spell_priority = require("spell_priority")
local menu = require("menu")
local my_target_selector = require("my_utility/my_target_selector")

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
    local player = get_local_player and get_local_player() or nil
    if not player then return nil, 0, false end

    local player_pos = player:get_position()
    local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}

    local max_range_sqr = max_range * max_range
    local cluster_radius_sqr = (cluster_radius or 6.0)
    cluster_radius_sqr = cluster_radius_sqr * cluster_radius_sqr

    local count = 0
    local has_boss_like = false

    local candidates = {}
    for _, e in ipairs(enemies) do
        local is_enemy = false
        if e then
            local ok, res = pcall(function() return e:is_enemy() end)
            is_enemy = ok and res or false
        end

        if is_enemy then
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
    local equipped_spells = get_equipped_spell_ids()

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
local next_move_time = 0.0  -- Timer to prevent spamming movement commands
local spell_last_cast_times = {}  -- Per-spell internal cooldown tracking

-- Spell classification for targeting (melee vs ranged)
local spell_classification = {
    zeal = "melee",
    clash = "melee",           -- Shield bash - melee
    brandish = "melee",
    shield_charge = "gap_closer",
    advance = "gap_closer",    -- Lunge forward
    holy_bolt = "ranged",
    blessed_hammer = "ranged_aoe",
    blessed_shield = "extended_melee", -- Extended melee (5.5-6.0), ricochets 3x
    falling_star = "ranged_aoe",
    arbiter_of_justice = "ranged_aoe",
    spear_of_the_heavens = "ranged",
    divine_lance = "melee",    -- Short range stab
    rally = "buff",
    defiance_aura = "buff",
    fanaticism_aura = "buff",
    holy_light_aura = "buff",
    condemn = "ranged_aoe",    -- Self-centered pull
    consecration = "ranged_aoe", -- Self-centered ground effect
    heavens_fury = "ranged_aoe", -- Self-centered AoE
    zenith = "melee",          -- Melee cleave
}

-- Spell range configuration
local spell_ranges = {
    zeal = 3.5,
    clash = 3.5,               -- Shield bash - melee range
    brandish = 4.0,
    shield_charge = 15.0,
    advance = 10.0,            -- Lunge range
    holy_bolt = 15.0,          -- Ranged throw
    blessed_hammer = 12.0,     -- Spiral AoE around player
    blessed_shield = 6.0,      -- Extended melee (5.5-6.0 range)
    falling_star = 15.0,
    arbiter_of_justice = 15.0,
    spear_of_the_heavens = 12.0,
    divine_lance = 5.0,        -- Short melee impale
    condemn = 8.0,             -- Self-centered pull radius
    consecration = 6.0,        -- Self-centered ground AoE
    heavens_fury = 10.0,       -- Self-centered AoE + seeking beams
    zenith = 6.0,              -- Melee cleave range
}

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

safe_on_update(function()
    if not safe_get_menu_element(menu.menu_elements.main_boolean, false) then
        return
    end

    -- Check orbwalker mode (like barb/sorc)
    if orbwalker then
        local current_orb_mode = orbwalker.get_orb_mode()
        if current_orb_mode == orb_mode.none then
            -- Allow if auto_play is active
            if not my_utility.is_auto_play_enabled() then
                return
            end
        end
    end

    local current_time = my_utility.safe_get_time()
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

    -- Define targeting ranges
    local melee_range = 3.5
    local ranged_range = 12.0
    local screen_range = 16.0

    local best_target = nil
    local movement_target = nil
    local enemy_count = 1

    if menu.menu_elements.weighted_targeting_enabled:get() then
        local scan_radius = menu.menu_elements.scan_radius:get()
        local refresh_rate = menu.menu_elements.scan_refresh_rate:get()
        local min_targets = menu.menu_elements.min_targets:get()
        local comparison_radius = menu.menu_elements.comparison_radius:get()
        
        local boss_weight, elite_weight, champion_weight, any_weight
        local damage_resistance_provider_weight, damage_resistance_receiver_penalty, horde_objective_weight, vulnerable_debuff_weight
        local normal_target_count, champion_target_count, elite_target_count, boss_target_count
        
        if menu.menu_elements.custom_enemy_sliders_enabled:get() then
            normal_target_count = menu.menu_elements.normal_target_count:get()
            champion_target_count = menu.menu_elements.champion_target_count:get()
            elite_target_count = menu.menu_elements.elite_target_count:get()
            boss_target_count = menu.menu_elements.boss_target_count:get()
            
            boss_weight = menu.menu_elements.boss_weight:get()
            elite_weight = menu.menu_elements.elite_weight:get()
            champion_weight = menu.menu_elements.champion_weight:get()
            any_weight = menu.menu_elements.any_weight:get()
        else
            normal_target_count = 1
            champion_target_count = 5
            elite_target_count = 5
            boss_target_count = 5
            
            boss_weight = 50
            elite_weight = 10
            champion_weight = 15
            any_weight = 2
        end

        if menu.menu_elements.custom_buff_weights_enabled:get() then
            damage_resistance_provider_weight = menu.menu_elements.damage_resistance_provider_weight:get()
            damage_resistance_receiver_penalty = menu.menu_elements.damage_resistance_receiver_penalty:get()
            horde_objective_weight = menu.menu_elements.horde_objective_weight:get()
            vulnerable_debuff_weight = menu.menu_elements.vulnerable_debuff_weight:get()
        else
            damage_resistance_provider_weight = 30
            damage_resistance_receiver_penalty = 5
            horde_objective_weight = 50
            vulnerable_debuff_weight = 1
        end
        
        local debug_enabled = menu.menu_elements.weighted_targeting_debug:get()
        
        best_target = my_target_selector.get_weighted_target(
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
            min_targets,
            normal_target_count,
            champion_target_count,
            elite_target_count,
            boss_target_count,
            debug_enabled
        )
        movement_target = best_target
    else
        local max_range = safe_get_menu_element(menu.menu_elements.max_targeting_range, 30)
        local cluster_radius = safe_get_menu_element(menu.menu_elements.cluster_radius, 6.0)
        local prefer_elites = safe_get_menu_element(menu.menu_elements.prefer_elites, true)
        best_target, enemy_count = get_best_target(max_range, cluster_radius, prefer_elites)
        movement_target = best_target
    end

    if not best_target then
        return
    end

    local best_target_position = best_target:get_position()

    local combo_enemy_count = safe_get_menu_element(menu.menu_elements.combo_enemy_count, 4)
    local combo_window = safe_get_menu_element(menu.menu_elements.combo_window, 0.8)

    local health_pct = my_utility.get_health_pct()
    local boss_defiance_hp_pct = safe_get_menu_element(menu.menu_elements.boss_defiance_hp_pct, 0.50)

    local treat_elite_as_boss = safe_get_menu_element(menu.menu_elements.treat_elite_as_boss, true)
    -- Nil-safe type checks per API docs (gameobject methods)
    local is_elite = false
    local is_champion = false
    local is_boss = false
    if best_target then
        local ok_elite, res_elite = pcall(function() return best_target:is_elite() end)
        local ok_champ, res_champ = pcall(function() return best_target:is_champion() end)
        local ok_boss, res_boss = pcall(function() return best_target:is_boss() end)
        is_elite = ok_elite and res_elite or false
        is_champion = ok_champ and res_champ or false
        is_boss = ok_boss and res_boss or false
    end
    local boss_or_elite_focus = best_target ~= nil and (is_boss or is_champion or (treat_elite_as_boss and is_elite))

    -- Perform area analysis once per update for AoE spell conditions
    local normal_target_count, elite_target_count, champion_target_count, boss_target_count
    if menu.menu_elements.custom_enemy_sliders_enabled:get() then
        normal_target_count = menu.menu_elements.normal_target_count:get()
        elite_target_count = menu.menu_elements.elite_target_count:get()
        champion_target_count = menu.menu_elements.champion_target_count:get()
        boss_target_count = menu.menu_elements.boss_target_count:get()
    else
        normal_target_count = 1
        elite_target_count = 5
        champion_target_count = 5
        boss_target_count = 5
    end
    
    local area_analysis = my_target_selector.analyze_target_area(
        player_position,
        menu.menu_elements.scan_radius:get(),
        normal_target_count,
        elite_target_count,
        champion_target_count,
        boss_target_count
    )

    -- Helper function to check AoE conditions for buff/debuff spells
    local function check_aoe_conditions(spell_menu_elements, area_analysis)
        if not spell_menu_elements then return true end
        if not area_analysis then return true end
        
        -- Check enemy type filter first
        local enemy_type_filter = spell_menu_elements.enemy_type_filter and spell_menu_elements.enemy_type_filter:get() or 0
        
        -- Filter: 0 = Any, 1 = Elite/Champ/Boss, 2 = Boss
        if enemy_type_filter == 2 then
            -- Boss only
            return (area_analysis.num_bosses or 0) > 0
        elseif enemy_type_filter == 1 then
            -- Elite/Champ/Boss
            return (area_analysis.num_elites or 0) > 0 or (area_analysis.num_champions or 0) > 0 or (area_analysis.num_bosses or 0) > 0
        end
        
        -- Filter is "Any" - check minimum targets in area if enabled
        if spell_menu_elements.use_minimum_weight and not spell_menu_elements.use_minimum_weight:get() then
            return true  -- Feature disabled, always allow cast
        end
        
        local minimum_targets = spell_menu_elements.minimum_weight and spell_menu_elements.minimum_weight:get() or 1
        return (area_analysis.total_target_count or 0) >= minimum_targets
    end

    -- Define spell parameters for consistent argument passing based on spell type
    -- Simplified to match sorc/barb pattern - just pass target for targeted spells
    local spell_params = {
        -- Core damage (highest priority for Hammerkuna)
        blessed_hammer = { args = {} },
        blessed_shield = { args = {best_target} },  -- Bouncing shield throw
        
        -- Targeted spells
        holy_bolt = { args = {best_target} },
        falling_star = { args = {best_target} },
        arbiter_of_justice = { args = {best_target} },
        spear_of_the_heavens = { args = {best_target} },
        divine_lance = { args = {best_target} },
        brandish = { args = {best_target} },
        advance = { args = {best_target} },
        shield_charge = { args = {best_target} },
        zeal = { args = {best_target} },
        clash = { args = {best_target} },  -- Shield bash generator
        
        -- Self-cast spells (auras, buffs, AoE around player)
        heavens_fury = { args = {} },
        zenith = { args = {} },
        condemn = { args = {} },
        consecration = { args = {} },
        rally = { args = {} },
        defiance_aura = { args = {} },
        fanaticism_aura = { args = {} },
        holy_light_aura = { args = {} },
    }

    -- Get equipped spells for spell casting logic
    local equipped_spells = get_equipped_spell_ids()

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
    
    for _, spell_name in ipairs(spell_priority) do
        local spell = spells[spell_name]
        -- Only process spells that are equipped (or bypass if debug enabled)
        local spell_equipped = spell and spell_data[spell_name] and spell_data[spell_name].spell_id and equipped_lookup[spell_data[spell_name].spell_id]
        local should_process = spell_equipped or (bypass_equipped and spell and spell_data[spell_name])
        
        if menu.menu_elements.enable_debug:get() and spell_data[spell_name] then
            if not spell_equipped then
                -- Only log once per second to avoid spam
                if not _G.paladin_last_equip_debug or (current_time - _G.paladin_last_equip_debug) > 2.0 then
                    dbg(spell_name .. " not equipped (spell_id: " .. tostring(spell_data[spell_name].spell_id) .. ")" .. (bypass_equipped and " [BYPASSED]" or ""))
                end
            end
        end
        
        if should_process then
            local params = spell_params[spell_name]
            if not params then
                if menu.menu_elements.enable_debug:get() then
                    dbg(spell_name .. " has no params in spell_params table!")
                end
                goto continue
            end
            
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
            
            -- Call spell's logics function with appropriate arguments (like sorc pattern)
            local args = params.args or {}
            local cast_successful, cooldown
            
            if #args == 0 then
                cast_successful, cooldown = spell.logics()
            elseif #args == 1 then
                cast_successful, cooldown = spell.logics(args[1])
            else
                cast_successful, cooldown = spell.logics(args[1], args[2])
            end
            
            cooldown = cooldown or 0.1  -- Default cooldown if not returned

            if cast_successful then
                -- Set cast_end_time to a SHORT animation lock (like sorc/barb)
                -- This prevents animation canceling, NOT spell rotation
                -- The actual per-spell cooldown is handled by spell_last_cast_times
                local animation_lock = cooldown or 0.05  -- Short animation lock
                cast_end_time = current_time + animation_lock
                
                -- Update internal cooldown tracking for this spell
                spell_last_cast_times[spell_name] = current_time
                
                if menu.menu_elements.enable_debug:get() then
                    dbg("Cast " .. spell_name .. " - animation lock " .. string.format("%.2f", animation_lock) .. "s")
                end
                return
            else
                if menu.menu_elements.enable_debug:get() then
                    -- Rate limit failed cast messages
                    if not _G.paladin_last_fail_debug or not _G.paladin_last_fail_debug[spell_name] or (current_time - _G.paladin_last_fail_debug[spell_name]) > 1.0 then
                        _G.paladin_last_fail_debug = _G.paladin_last_fail_debug or {}
                        _G.paladin_last_fail_debug[spell_name] = current_time
                        dbg(spell_name .. " logics returned false")
                    end
                end
            end
            
            ::continue::
        end
    end
    
    -- Auto play engage far away monsters (like sorc)
    local is_auto_play = my_utility.is_auto_play_enabled()
    if is_auto_play and movement_target then
        local movement_target_position = movement_target:get_position()
        local move_pos = movement_target_position:get_extended(player_position, 3.0)
        if pathfinder and pathfinder.request_move then
            pathfinder.request_move(move_pos)
        end
    end
end)

if console and type(console.print) == "function" then
    console.print("Paladin_Rotation | Version 1.2 (Season 11 Meta Optimized - Dec 2025)")
end
