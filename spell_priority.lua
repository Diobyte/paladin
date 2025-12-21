-- Paladin Spell Priority Configuration
-- Defines spell casting order for all 12 paladin builds
-- Build indices: 0=default, 1-11=specialized builds

local my_utility = require("my_utility/my_utility");
local spell_data = require("my_utility/spell_data");

-- Function to get base spell priority (without item adjustments)
local function get_base_spell_priority(build_index)
    if build_index == 1 then -- Judgement Nuke
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            "evade",

            -- High priority for Judgement chain: mark, pop, auras, mobility, ultimate
            "brandish",
            "blessed_shield",
            "fanaticism_aura",
            "defiance_aura",
            "falling_star",
            "arbiter_of_justice",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Other defensives and auras
            "holy_light_aura",
            "rally",

            -- Main damage abilities
            "blessed_hammer",
            "zeal",
            "divine_lance",
            "condemn",
            "shield_bash",

            -- Other mobility
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 2 then -- Hammerkuna
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            "evade",

            -- Blessed Hammer spam with auras and mobility - META AOE BUILD
            "blessed_hammer",
            "fanaticism_aura",
            "defiance_aura",
            "falling_star",
            "rally",
            "arbiter_of_justice",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Other defensives and auras
            "holy_light_aura",

            -- Main damage abilities
            "zeal",
            "divine_lance",
            "brandish",
            "shield_bash",
            "condemn",

            -- Other mobility
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 3 then -- Arbiter
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            "evade",

            -- Arbiter focused with mobility and auras - PURE ULTIMATE BUILD
            "arbiter_of_justice",
            "falling_star",
            "fanaticism_aura",
            "defiance_aura",
            "holy_light_aura",
            "rally",

            -- Wrath builders for Arbiter
            "zeal",
            "divine_lance",
            "spear_of_the_heavens",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "aegis",
            "fortress",
            "purify",

            -- Main damage abilities
            "blessed_hammer",
            "condemn",
            "blessed_shield",
            "brandish",
            "shield_bash",

            -- Mobility
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 4 then -- Captain America
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            "evade",

            -- Blessed Shield focused with auras and mobility - SINGLE TARGET BUILD
            "blessed_shield",
            "fanaticism_aura",
            "defiance_aura",
            "rally",
            "falling_star",
            "arbiter_of_justice",

            -- Shield synergy
            "shield_bash",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Other defensives and auras
            "holy_light_aura",

            -- Main damage abilities
            "blessed_hammer",
            "condemn",
            "zeal",
            "divine_lance",
            "brandish",

            -- Other mobility
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 5 then -- Shield Bash
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            "evade",

            -- Shield bash focused with charge and auras - MELEE BUILD
            "shield_bash",
            "clash",
            "shield_charge",
            "fanaticism_aura",
            "defiance_aura",
            "holy_light_aura",
            "rally",
            "falling_star",

            -- Ultimates
            "arbiter_of_justice",
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Main damage abilities
            "blessed_hammer",
            "condemn",
            "blessed_shield",
            "zeal",
            "divine_lance",
            "brandish",

            -- Other mobility
            "advance",

            -- Filler abilities
            "holy_bolt",
            "consecration",
        }
    elseif build_index == 6 then -- Wing Strikes
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            "evade",

            -- Mobility and ultimate focused - HIGH MOBILITY BUILD
            "falling_star",
            "arbiter_of_justice",
            "fanaticism_aura",
            "defiance_aura",
            "rally",
            "blessed_hammer",

            -- High mobility
            "advance",
            "shield_charge",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Other defensives and auras
            "holy_light_aura",

            -- Main damage abilities
            "condemn",
            "blessed_shield",
            "zeal",
            "divine_lance",
            "brandish",
            "shield_bash",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 7 then -- Evade Hammer
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and damage
            "paladin_evade",
            -- Evade focused with Blessed Hammer spam - META EVADE BUILD
            "evade",
            "blessed_hammer",
            "fanaticism_aura",
            "defiance_aura",
            "consecration",
            "rally",

            -- Other ultimates
            "arbiter_of_justice",
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Other defensives and auras
            "holy_light_aura",

            -- Main damage abilities
            "zeal",
            "divine_lance",
            "brandish",
            "shield_bash",
            "condemn",

            -- Other mobility
            "shield_charge",
            "falling_star",
            "advance",

            -- Filler abilities
            "holy_bolt",
            "clash",
        }
    elseif build_index == 8 then -- Arbiter Evade
        return {
            -- Arbiter with evade for high mobility and ultimate spam - META BUILD
            "paladin_evade",
            "evade",
            "arbiter_of_justice",
            "falling_star",
            "fanaticism_aura",
            "defiance_aura",
            "holy_light_aura",

            -- Wrath builders
            "zeal",
            "divine_lance",
            "spear_of_the_heavens",

            -- Other defensives and auras
            "rally",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "aegis",
            "fortress",
            "purify",

            -- Main damage abilities
            "blessed_hammer",
            "condemn",
            "blessed_shield",
            "brandish",
            "shield_bash",

            -- Other mobility
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "advance",
            "consecration",
        }
    elseif build_index == 9 then -- Heaven's Fury
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            -- HIGHEST PRIORITY - Evade for mobility and safety
            "evade",

            -- Core auras
            "fanaticism_aura",
            "defiance_aura",
            "holy_light_aura",
            "rally",

            -- High priority ultimates and mobility
            "heavens_fury",
            "arbiter_of_justice",
            "falling_star",
            "blessed_hammer",

            -- Other ultimates
            "zenith",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Main damage abilities
            "blessed_shield",
            "condemn",
            "zeal",
            "divine_lance",
            "brandish",

            -- Mobility
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 10 then -- Spear
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            -- HIGHEST PRIORITY - Evade for mobility and safety
            "evade",

            -- Spear of the Heavens focused - RANGED ULTIMATE BUILD
            "spear_of_the_heavens",
            "fanaticism_aura",
            "defiance_aura",
            "rally",
            "falling_star",
            "blessed_hammer",

            -- Wrath builders
            "zeal",
            "divine_lance",

            -- Other ultimates
            "arbiter_of_justice",
            "zenith",
            "heavens_fury",
            "aegis",
            "fortress",
            "purify",

            -- Other defensives and auras
            "holy_light_aura",

            -- Main damage abilities
            "condemn",
            "blessed_shield",
            "brandish",
            "shield_bash",

            -- Mobility
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 11 then -- Zenith Tank
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            -- HIGHEST PRIORITY - Evade for mobility and safety
            "evade",

            -- Zenith and Aegis focused - TANKY ULTIMATE BUILD
            "zenith",
            "aegis",
            "fanaticism_aura",
            "defiance_aura",
            "holy_light_aura",
            "rally",

            -- Other ultimates
            "arbiter_of_justice",
            "heavens_fury",
            "spear_of_the_heavens",
            "fortress",
            "purify",

            -- Main damage abilities
            "blessed_hammer",
            "condemn",
            "blessed_shield",
            "zeal",
            "divine_lance",
            "brandish",

            -- Mobility
            "falling_star",
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 12 then -- Auradin
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            "evade",

            -- Holy Light Aura - PRIMARY DAMAGE SOURCE (emanation from allies) + ACTIVE for burst/healing
            "holy_light_aura",

            -- Falling Star - ASCENT INTO ARBITER oath setup (critical for power)
            "falling_star",

            -- High priority mobility for positioning (March of the Stalwart Soul, Flash of the Blade)
            "advance",
            "shield_charge",

            -- Consecration - POWERFUL BUFFS from Sundered Night (auto-cast)
            "consecration",

            -- Rally - FAITH RESTORATION + UNSTOPPABLE/RESOLVE stacks for damage reduction
            "rally",

            -- Pull enemies into Holy Light Aura range
            "condemn",

            -- Supporting auras - MAINTAIN CONSTANTLY for buffs and Resplendence glyph refresh
            "fanaticism_aura",
            "defiance_aura",

            -- Defensive ultimate for survivability
            "aegis",

            -- Blessed Hammer - PRIMARY SPAM SKILL (Faith gen, Holy Light procs, high frequency)
            "blessed_hammer",

            -- Other damage abilities that synergize with Holy Light Aura
            "zeal",
            "divine_lance",

            -- Purify - REMOVE DEBUFFS that could interrupt aura uptime
            "purify",

            -- Other ultimates (lower priority in Auradin)
            "arbiter_of_justice",
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "fortress",

            -- Other utility
            "blessed_shield",
            "brandish",

            -- Filler abilities
            "holy_bolt",
            "clash",
        }
    else -- Default build (build_index == 0 or any other value)
        return {
            -- Core mobility and safety
            "paladin_evade",
            "evade",

            -- Core auras
            "fanaticism_aura",
            "defiance_aura",
            "holy_light_aura",
            "rally",

            -- High priority ultimates and mobility
            "arbiter_of_justice",
            "falling_star",
            "blessed_hammer",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Main damage abilities
            "blessed_shield",
            "condemn",
            "zeal",
            "divine_lance",
            "brandish",

            -- Mobility
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    end
end

-- Function to analyze equipped items and adjust spell priorities
local function adjust_priorities_for_items(base_priorities)
    local local_player = get_local_player()
    if not local_player then
        return base_priorities
    end
    -- Get equipped items to analyze stats
    local equipped_items = local_player:get_equipped_items()
    local attack_speed_total = 0
    local cdr_total = 0
    local crit_damage_total = 0
    local resource_gen_total = 0

    -- Analyze each equipped item for relevant stats
    for _, item in ipairs(equipped_items) do
        if item then
            local affixes = item:get_affixes()
            for _, affix in ipairs(affixes) do
                if affix then
                    local name = affix:get_name()
                    local value = affix:get_roll()
                    if rawget(_G, 'DEBUG_SPELL_PRIORITY') then print('DEBUG: affix:', name, value) end
                    -- Check for attack speed (reduces aura priority)
                    if name:find("Attack Speed") or name:find("attacks_per_second") then
                        attack_speed_total = attack_speed_total + value
                    end
                    -- Check for critical hit damage
                    if name:find("Critical Strike Damage") or name:find("crit_damage") then
                        crit_damage_total = crit_damage_total + value
                    end
                    -- Check for resource generation
                    if name:find("Resource Generation") or name:find("resource_generation") then
                        resource_gen_total = resource_gen_total + value
                    end
                end
            end
        end
    end

    -- Compute cooldown reduction centrally using my_utility helper for consistency
    local my_utility = require('my_utility/my_utility')
    cdr_total = my_utility.get_total_cooldown_reduction_pct() or 0

    -- Create adjusted priorities based on item stats
    local adjusted_priorities = {}

    -- Debug: expose aggregate stats when running tests
    if rawget(_G, 'DEBUG_SPELL_PRIORITY') then
        print('DEBUG: attack_speed_total=', attack_speed_total, 'cdr_total=', cdr_total, 'crit=', crit_damage_total,
            'resource_gen=', resource_gen_total)
    end

    -- If high attack speed from items, reduce aura priority
    local aura_priority_reduction = 0
    if attack_speed_total > 50 then -- High attack speed from gear
        aura_priority_reduction = 2 -- Move auras down in priority
    elseif attack_speed_total > 30 then
        aura_priority_reduction = 1
    end

    -- If high CDR, increase ultimate priority
    local ultimate_priority_boost = 0
    if cdr_total > 20 then
        ultimate_priority_boost = 2
    elseif cdr_total > 10 then
        ultimate_priority_boost = 1
    end

    -- Apply adjustments to the priority list
    for i, spell_name in ipairs(base_priorities) do
        local new_position = i

        -- Adjust aura positions
        if (spell_name == "fanaticism_aura" or spell_name == "defiance_aura") and aura_priority_reduction > 0 then
            new_position = math.min(#base_priorities, i + aura_priority_reduction)
        end

        -- Adjust ultimate positions
        if (spell_name == "arbiter_of_justice" or spell_name == "heavens_fury" or
                spell_name == "spear_of_the_heavens" or spell_name == "zenith" or
                spell_name == "aegis") and ultimate_priority_boost > 0 then
            new_position = math.max(1, i - ultimate_priority_boost)
        end

        -- Boost certain skills based on crit damage
        if crit_damage_total > 100 and (spell_name == "condemn" or spell_name == "blessed_shield") then
            new_position = math.max(1, i - 1)
        end

        -- Boost spam skills if high resource generation
        if resource_gen_total > 20 and (spell_name == "blessed_hammer" or spell_name == "zeal") then
            new_position = math.max(1, i - 1)
        end

        adjusted_priorities[new_position] = adjusted_priorities[new_position] or {}
        table.insert(adjusted_priorities[new_position], spell_name)
    end

    -- Flatten the adjusted priorities while preserving target positions
    local n = #base_priorities
    local final_priorities = {}
    -- Use a sentinel false to create contiguous slots so table.insert appends after slot n
    for i = 1, n do final_priorities[i] = false end

    -- Place adjusted spells deterministically by scanning positions from 1..n
    if rawget(_G, 'DEBUG_SPELL_PRIORITY') then
        print('DEBUG: adjusted_priorities dump:')
        for k, v in pairs(adjusted_priorities) do
            io.write('  pos=', k, ' ->')
            for _, name in ipairs(v) do io.write(' ', name) end
            print('')
        end
    end

    local tail = {}
    for pos = 1, n do
        local spell_list = adjusted_priorities[pos]
        if spell_list then
            for _, spell_name in ipairs(spell_list) do
                local p = pos
                while p <= n and final_priorities[p] ~= false do p = p + 1 end
                if p <= n then
                    final_priorities[p] = spell_name
                else
                    table.insert(tail, spell_name)
                end
            end
        end
    end

    -- Append any tail items beyond n
    for _, name in ipairs(tail) do table.insert(final_priorities, name) end

    -- Debug: show state BEFORE fill
    if rawget(_G, 'DEBUG_SPELL_PRIORITY') then
        print('DEBUG: before fill final_priorities len=', #final_priorities)
        for i = 1, #final_priorities do print('  prefill', i, tostring(final_priorities[i])) end
    end

    -- Fill remaining slots with base priorities preserving order
    local placed = {}
    for _, name in ipairs(final_priorities) do if name then placed[name] = true end end
    local fill_idx = 1
    for _, spell_name in ipairs(base_priorities) do
        if not placed[spell_name] then
            while final_priorities[fill_idx] ~= false do fill_idx = fill_idx + 1 end
            final_priorities[fill_idx] = spell_name
            placed[spell_name] = true
        end
    end

    if rawget(_G, 'DEBUG_SPELL_PRIORITY') then
        print('DEBUG: final_priorities (with indices):')
        for i = 1, #final_priorities do print(i, tostring(final_priorities[i])) end
    end

    -- If test harness requests the prefill (sparse) table, return it directly for inspection
    if rawget(_G, 'DEBUG_SPELL_PRIORITY_PREFILL') then
        return final_priorities
    end

    -- Compact results: remove sentinel false placeholders and return contiguous list
    local result = {}
    for i = 1, #final_priorities do
        local name = final_priorities[i]
        if name and name ~= false then
            table.insert(result, name)
        end
    end

    return result
end

-- Function for dynamic runtime adjustments based on current game state
local function apply_dynamic_adjustments(base_priorities, build_index)
    local local_player = get_local_player()
    if not local_player then
        return base_priorities
    end

    local adjusted_priorities = {}
    local faith_current = local_player:get_primary_resource_current() -- Faith resource
    local faith_max = local_player:get_primary_resource_max()

    -- Intelligent Faith-based adjustments
    local faith_emergency = faith_current < (faith_max * 0.2) -- Critical: prioritize restoration
    local faith_low = faith_current < (faith_max * 0.4)       -- Low: prioritize generation
    local faith_moderate = faith_current < (faith_max * 0.6)  -- Moderate: slight boost

    -- Faith priority adjustments
    local rally_boost = 0
    local generator_boost = 0
    local consumer_penalty = 0

    if faith_emergency then
        rally_boost = 5      -- Emergency Rally
        consumer_penalty = 3 -- Deprioritize consumers
    elseif faith_low then
        generator_boost = 3  -- Boost generators
        consumer_penalty = 1
    elseif faith_moderate then
        generator_boost = 1
    end

    -- Health-based defensive adjustments
    local health_percent = (local_player:get_current_health() / local_player:get_max_health()) * 100
    local defensive_boost = 0
    if health_percent < 30 then     -- Critical health
        defensive_boost = 3
    elseif health_percent < 50 then -- Low health
        defensive_boost = 2
    elseif health_percent < 70 then -- Moderate health
        defensive_boost = 1
    end

    -- Apply dynamic adjustments
    for i, spell_name in ipairs(base_priorities) do
        local new_position = i

        -- Intelligent Faith management
        if spell_name == "rally" and rally_boost > 0 then
            new_position = math.max(1, i - rally_boost)
        elseif (spell_name == "blessed_hammer" or spell_name == "zeal") and generator_boost > 0 then
            new_position = math.max(1, i - generator_boost)
        elseif consumer_penalty > 0 and (spell_name == "arbiter_of_justice" or spell_name == "heavens_fury" or spell_name == "spear_of_the_heavens") then
            new_position = math.min(#base_priorities, i + consumer_penalty)
        end

        -- Build-specific Faith optimizations
        if build_index == 2 then -- Hammerkuna: Always prioritize Blessed Hammer for Faith gen
            if spell_name == "blessed_hammer" then
                new_position = math.max(1, i - 1)
            end
        elseif build_index == 3 then -- Arbiter: Prioritize Wrath generators (proxy via Faith generators since Wrath not directly accessible)
            if spell_name == "zeal" or spell_name == "divine_lance" then
                new_position = math.max(1, i - 2)
            end
        elseif build_index == 10 then -- Spear: Prioritize Wrath generators (proxy via Faith generators since Wrath not directly accessible)
            if spell_name == "zeal" or spell_name == "divine_lance" then
                new_position = math.max(1, i - 2)
            end
        end

        -- Defensive boosts when health is low
        if defensive_boost > 0 and (spell_name == "aegis" or spell_name == "purify" or spell_name == "rally") then
            new_position = math.max(1, i - defensive_boost)
        end

        -- High Faith: Boost one ultimate consumer (mutual exclusion)
        if faith_current > (faith_max * 0.8) then
            local ultimates = { "arbiter_of_justice", "heavens_fury", "spear_of_the_heavens", "zenith", "aegis",
                "fortress" }
            local util = package.loaded and package.loaded['utility'] or utility
            for _, ult_name in ipairs(ultimates) do
                if spell_name == ult_name and spell_data[ult_name] and type(util) == "table" and type(util.is_spell_ready) == "function" and util.is_spell_ready(spell_data[ult_name].spell_id) then
                    new_position = math.max(1, i - 1)
                    break -- Only boost the first ready ultimate
                end
            end
        end

        -- Auradin-specific dynamic adjustments
        if build_index == 12 then
            -- Emergency: If health critical, prioritize Aegis immediately
            if health_percent < 25 and spell_name == "aegis" then
                new_position = 2 -- Right after evade
            end

            -- Boost Condemn if enemies are far (need to pull into aura range)
            if spell_name == "condemn" then
                local enemies = actors_manager.get_enemy_actors()
                local far_enemies = 0
                for _, enemy in ipairs(enemies) do
                    local dist = enemy:get_position():dist_to(local_player:get_position())
                    if dist > 8 then -- Beyond typical aura range
                        far_enemies = far_enemies + 1
                    end
                end
                if far_enemies > 0 then
                    new_position = math.max(1, i - 2) -- Boost condemn
                end
            end
        end

        -- Affordability check: Deprioritize spells that cost more Faith than available
        if spell_data[spell_name] and spell_data[spell_name].faith_cost and faith_current < spell_data[spell_name].faith_cost then
            new_position = #base_priorities
        end

        -- Buff check: Boost auras if not active
        if (spell_name == "fanaticism_aura" or spell_name == "defiance_aura" or spell_name == "holy_light_aura") then
            if spell_data[spell_name] and not my_utility.is_buff_active(spell_data[spell_name].spell_id, spell_data[spell_name].buff_id) then
                new_position = math.max(1, i - 2)
            end
        end

        -- Enemy count: Boost AOE spells if many enemies
        local enemy_count = #actors_manager.get_enemy_actors()
        local aoe_boost = 0
        if enemy_count >= 5 then
            aoe_boost = 2
        elseif enemy_count >= 3 then
            aoe_boost = 1
        end
        if aoe_boost > 0 and (spell_name == "blessed_hammer" or spell_name == "heavens_fury" or spell_name == "consecration") then
            new_position = math.max(1, i - aoe_boost)
        end

        adjusted_priorities[new_position] = adjusted_priorities[new_position] or {}
        table.insert(adjusted_priorities[new_position], spell_name)
    end

    -- Place adjusted spells deterministically by scanning positions from 1..n
    local n = #base_priorities
    local final_priorities = {}
    for i = 1, n do final_priorities[i] = false end

    local tail = {}
    for pos = 1, n do
        local spell_list = adjusted_priorities[pos]
        if spell_list then
            for _, spell_name in ipairs(spell_list) do
                local p = pos
                while p <= n and final_priorities[p] ~= false do p = p + 1 end
                if p <= n then
                    final_priorities[p] = spell_name
                else
                    table.insert(tail, spell_name)
                end
            end
        end
    end

    for _, name in ipairs(tail) do table.insert(final_priorities, name) end

    if rawget(_G, 'DEBUG_SPELL_PRIORITY') then
        print('DEBUG: apply_dynamic_adjustments final_priorities (with indices):')
        for i = 1, #final_priorities do print(i, tostring(final_priorities[i])) end
    end

    if rawget(_G, 'DEBUG_SPELL_PRIORITY_PREFILL') then
        return final_priorities
    end

    -- Compact results to contiguous list
    local result = {}
    for i = 1, #final_priorities do
        local name = final_priorities[i]
        if name and name ~= false then table.insert(result, name) end
    end

    return result
end

-- Main function that applies all adjustments
local function get_spell_priority(build_index)
    local base_priorities = get_base_spell_priority(build_index)
    local item_adjusted = adjust_priorities_for_items(base_priorities)
    return apply_dynamic_adjustments(item_adjusted, build_index)
end

-- Expose internal helpers for unit testing via a callable table
local api = {}
setmetatable(api, { __call = function(self, build_index) return get_spell_priority(build_index) end })
api.get_base_spell_priority = get_base_spell_priority
api.adjust_priorities_for_items = adjust_priorities_for_items
api.apply_dynamic_adjustments = apply_dynamic_adjustments

return api
