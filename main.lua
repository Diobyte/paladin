if package and package.loaded then
    package.loaded["menu"] = nil
    package.loaded["spell_priority"] = nil
    package.loaded["my_utility/my_utility"] = nil
    package.loaded["my_utility/spell_data"] = nil
    package.loaded["spells/holy_bolt"] = nil
    package.loaded["spells/blessed_hammer"] = nil
    package.loaded["spells/falling_star"] = nil
    package.loaded["spells/arbiter_of_justice"] = nil
    package.loaded["spells/rally"] = nil
    package.loaded["spells/defiance_aura"] = nil
    package.loaded["spells/fanaticism_aura"] = nil
    package.loaded["spells/holy_light_aura"] = nil
    package.loaded["spells/evade"] = nil
    package.loaded["spells/zeal"] = nil
    package.loaded["spells/shield_charge"] = nil
    package.loaded["spells/spear_of_the_heavens"] = nil
    package.loaded["spells/divine_lance"] = nil
    package.loaded["spells/brandish"] = nil
end

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
    holy_bolt = require("spells/holy_bolt"),
    blessed_hammer = require("spells/blessed_hammer"),
    falling_star = require("spells/falling_star"),
    arbiter_of_justice = require("spells/arbiter_of_justice"),
    rally = require("spells/rally"),
    defiance_aura = require("spells/defiance_aura"),
    fanaticism_aura = require("spells/fanaticism_aura"),
    holy_light_aura = require("spells/holy_light_aura"),
    evade = require("spells/evade"),
    zeal = require("spells/zeal"),
    shield_charge = require("spells/shield_charge"),
    spear_of_the_heavens = require("spells/spear_of_the_heavens"),
    divine_lance = require("spells/divine_lance"),
    brandish = require("spells/brandish"),
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
        if menu.menu_elements.evade_min_delay then
            menu.menu_elements.evade_min_delay:render("Evade Min Delay", "", 2)
        end
        menu.menu_elements.rally_resource_pct:render("Rally Resource %", "", 2)
        if menu.menu_elements.holy_bolt_resource_pct then
            menu.menu_elements.holy_bolt_resource_pct:render("Holy Bolt Resource %", "", 2)
        end
        if menu.menu_elements.boss_defiance_hp_pct then
            menu.menu_elements.boss_defiance_hp_pct:render("Boss Defiance HP %", "", 2)
        end
        
        menu.menu_elements.settings_tree:pop()
    end

    menu.menu_elements.enable_debug:render("Debug", "")

    -- Get equipped spells
    local equipped_spells = get_equipped_spell_ids()
    table.insert(equipped_spells, spell_data.evade.spell_id) -- add evade to the list

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

    if menu.menu_elements.main_tree:push("Oath Selector") then
        local oath_options = {"None", "Oath of the Zealot", "Oath of the Protector", "Oath of the Avenger", "Oath of the Light"}
        menu.menu_elements.oath_selector:render("Active Oath", oath_options, "")
        menu.menu_elements.main_tree:pop()
    end

    menu.menu_elements.main_tree:pop()
end)

local cast_end_time = 0.0

safe_on_update(function()
    if not safe_get_menu_element(menu.menu_elements.main_boolean, false) then
        return
    end

    local now = my_utility.safe_get_time()
    if now < cast_end_time then
        return
    end

    local player = get_local_player()
    if not player then return end
    local player_position = player:get_position()

    local best_target = nil
    local enemy_count = 1 -- Default to 1 for weighted targeting

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
    else
        local max_range = safe_get_menu_element(menu.menu_elements.max_targeting_range, 30)
        local cluster_radius = safe_get_menu_element(menu.menu_elements.cluster_radius, 6.0)
        local prefer_elites = safe_get_menu_element(menu.menu_elements.prefer_elites, true)
        best_target, enemy_count = get_best_target(max_range, cluster_radius, prefer_elites)
    end

    if not best_target then
        return
    end

    local combo_enemy_count = safe_get_menu_element(menu.menu_elements.combo_enemy_count, 4)
    local combo_window = safe_get_menu_element(menu.menu_elements.combo_window, 0.8)

    local health_pct = my_utility.get_health_pct()
    local boss_defiance_hp_pct = safe_get_menu_element(menu.menu_elements.boss_defiance_hp_pct, 0.50)

    local treat_elite_as_boss = safe_get_menu_element(menu.menu_elements.treat_elite_as_boss, true)
    local is_elite = best_target and best_target.is_elite and best_target:is_elite() or false
    local is_champion = best_target and best_target.is_champion and best_target:is_champion() or false
    local is_boss = best_target and best_target.is_boss and best_target:is_boss() or false
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
        
        -- Check enemy type filter first
        local enemy_type_filter = spell_menu_elements.enemy_type_filter and spell_menu_elements.enemy_type_filter:get() or 0
        
        -- Filter: 0 = Any, 1 = Elite/Champ/Boss, 2 = Elite/Boss, 3 = Boss
        if enemy_type_filter == 3 then
            -- Boss only
            return area_analysis.num_bosses > 0
        elseif enemy_type_filter == 2 then
            -- Elite/Boss
            return area_analysis.num_elites > 0 or area_analysis.num_bosses > 0
        elseif enemy_type_filter == 1 then
            -- Elite/Champ/Boss
            return area_analysis.num_elites > 0 or area_analysis.num_champions > 0 or area_analysis.num_bosses > 0
        end
        
        -- Filter is "Any" - check minimum targets in area if enabled
        if spell_menu_elements.use_minimum_weight and not spell_menu_elements.use_minimum_weight:get() then
            return true  -- Feature disabled, always allow cast
        end
        
        local minimum_targets = spell_menu_elements.minimum_weight and spell_menu_elements.minimum_weight:get() or 1
        return area_analysis.total_target_count >= minimum_targets
    end

    -- Define spell parameters for consistent argument passing based on spell type
    local spell_params = {
        holy_bolt = { args = {best_target} },
        blessed_hammer = { args = {best_target} },
        falling_star = { args = {best_target} },
        arbiter_of_justice = { args = {best_target} },
        rally = { args = {}, custom_check = function()
            if spells.rally and spells.rally.menu_elements then
                return check_aoe_conditions(spells.rally.menu_elements, area_analysis)
            end
            return true
        end },
        defiance_aura = { args = {}, custom_check = function()
            if spells.defiance_aura and spells.defiance_aura.menu_elements then
                return check_aoe_conditions(spells.defiance_aura.menu_elements, area_analysis)
            end
            return true
        end },
        fanaticism_aura = { args = {}, custom_check = function()
            if spells.fanaticism_aura and spells.fanaticism_aura.menu_elements then
                return check_aoe_conditions(spells.fanaticism_aura.menu_elements, area_analysis)
            end
            return true
        end },
        holy_light_aura = { args = {}, custom_check = function()
            if spells.holy_light_aura and spells.holy_light_aura.menu_elements then
                return check_aoe_conditions(spells.holy_light_aura.menu_elements, area_analysis)
            end
            return true
        end },
        evade = { args = {best_target} },
        zeal = { args = {best_target} },
        shield_charge = { args = {best_target} },
        spear_of_the_heavens = { args = {best_target} },
        divine_lance = { args = {best_target} },
        brandish = { args = {best_target} },
    }

    -- Get equipped spells for spell casting logic
    local equipped_spells = get_equipped_spell_ids()
    table.insert(equipped_spells, spell_data.evade.spell_id) -- add evade to the list

    -- Create a lookup table for equipped spells
    local equipped_lookup = {}
    for _, spell_id in ipairs(equipped_spells) do
        equipped_lookup[spell_id] = true
    end

    for _, spell_name in ipairs(spell_priority) do
        local spell = spells[spell_name]
        -- Only process spells that are equipped
        if spell and spell_data[spell_name] and spell_data[spell_name].spell_id and equipped_lookup[spell_data[spell_name].spell_id] then
            local params = spell_params[spell_name]
            if params then
                -- Check any custom pre-conditions if defined
                local should_cast = true
                if params.custom_check ~= nil then
                    should_cast = params.custom_check()
                end

                if should_cast then
                    local args = params.args or {}
                    local cast_successful = false
                    
                    if #args == 0 then
                        cast_successful = spell.logics(area_analysis)
                    elseif #args == 1 then
                        cast_successful = spell.logics(args[1], area_analysis)
                    end

                    if cast_successful then
                        cast_end_time = now + 0.05
                        return
                    end
                end
            end
        end
    end
end)

if console and type(console.print) == "function" then
    console.print("Paladin_Rotation | Version 1")
end
