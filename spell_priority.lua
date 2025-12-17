-- Paladin Spell Priority Configuration
-- Defines spell casting order for all 12 paladin builds
-- Build indices: 0=default, 1-11=specialized builds

-- Function to get base spell priority (without item adjustments)
local function get_base_spell_priority(build_index)
    if build_index == 1 then  -- Judgement Nuke Paladin
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
            "condemn",
            "zeal",
            "divine_lance",

            -- Other mobility
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 2 then  -- Blessed Hammer (Hammerkuna)
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
            "condemn",
            "blessed_shield",
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
    elseif build_index == 3 then  -- Arbiter Paladin
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

            -- Mobility only - no other ultimates or damage skills for pure Arbiter
            "advance",
            "shield_charge",
        }
    elseif build_index == 4 then  -- Blessed Shield (Captain America)
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
    elseif build_index == 5 then  -- Shield Bash Valkyrie
        return {
            -- HIGHEST PRIORITY - Enhanced Evade for mobility and safety
            "paladin_evade",
            "evade",

            -- Shield bash focused with charge and auras - MELEE BUILD
            "clash",
            "shield_charge",
            "fanaticism_aura",
            "defiance_aura",
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
    elseif build_index == 6 then  -- Holy Avenger Wing Strikes
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

            -- Other mobility
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 7 then  -- Evade Hammerdin
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
            "condemn",
            "blessed_shield",
            "zeal",
            "divine_lance",
            "brandish",

            -- Other mobility
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "falling_star",
        }
    elseif build_index == 8 then  -- Arbiter Evade
        return {
            -- Arbiter with evade for high mobility and ultimate spam - META BUILD
            "paladin_evade",
            "evade",
            "arbiter_of_justice",
            "falling_star",
            "fanaticism_aura",
            "defiance_aura",
            "holy_light_aura",

            -- Other defensives and auras
            "rally",

            -- Other ultimates
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
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "advance",
            "consecration",
        }
    elseif build_index == 9 then  -- Heaven's Fury Spam
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
    elseif build_index == 10 then  -- Spear of the Heavens
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
    elseif build_index == 11 then  -- Zenith Aegis Tank
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
    elseif build_index == 13 then  -- Auradin Holy Light Aura
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

            -- Pull enemies into Holy Light Aura range
            "condemn",

            -- Rally - FAITH RESTORATION + UNSTOPPABLE/RESOLVE stacks for damage reduction
            "rally",

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
    else  -- Default build (build_index == 0 or any other value)
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
                    -- Check for attack speed (reduces aura priority)
                    if name:find("Attack Speed") or name:find("attacks_per_second") then
                        attack_speed_total = attack_speed_total + value
                    end
                    -- Check for cooldown reduction (increases ultimate priority)
                    if name:find("Cooldown Reduction") or name:find("cooldown_reduction") then
                        cdr_total = cdr_total + value
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

    -- Create adjusted priorities based on item stats
    local adjusted_priorities = {}

    -- If high attack speed from items, reduce aura priority
    local aura_priority_reduction = 0
    if attack_speed_total > 50 then  -- High attack speed from gear
        aura_priority_reduction = 2  -- Move auras down in priority
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

    -- Flatten the adjusted priorities
    local final_priorities = {}
    for i = 1, #base_priorities do
        if adjusted_priorities[i] then
            for _, spell_name in ipairs(adjusted_priorities[i]) do
                table.insert(final_priorities, spell_name)
            end
        end
    end

    return final_priorities
end

-- Function for dynamic runtime adjustments based on current game state
local function apply_dynamic_adjustments(base_priorities, build_index)
    local local_player = get_local_player()
    if not local_player then
        return base_priorities
    end

    local adjusted_priorities = {}
    local faith_current = local_player:get_primary_resource_current()  -- Faith resource
    local faith_max = local_player:get_primary_resource_max()

    -- Faith-based adjustments (boost Faith generation when low)
    local faith_priority_boost = 0
    if faith_current < (faith_max * 0.25) then  -- Faith below 25% - EMERGENCY
        faith_priority_boost = 4
    elseif faith_current < (faith_max * 0.4) then  -- Faith below 40%
        faith_priority_boost = 3
    elseif faith_current < (faith_max * 0.6) then  -- Faith below 60%
        faith_priority_boost = 2
    elseif faith_current < (faith_max * 0.8) then  -- Faith below 80%
        faith_priority_boost = 1
    end

    -- Health-based defensive adjustments
    local health_percent = (local_player:get_current_health() / local_player:get_max_health()) * 100
    local defensive_boost = 0
    if health_percent < 30 then  -- Critical health
        defensive_boost = 3
    elseif health_percent < 50 then  -- Low health
        defensive_boost = 2
    elseif health_percent < 70 then  -- Moderate health
        defensive_boost = 1
    end

    -- Apply dynamic adjustments
    for i, spell_name in ipairs(base_priorities) do
        local new_position = i

        -- Faith management (all builds)
        if faith_priority_boost > 0 and (spell_name == "blessed_hammer" or spell_name == "zeal" or spell_name == "rally") then
            new_position = math.max(1, i - faith_priority_boost)
        end

        -- Defensive boosts when health is low
        if defensive_boost > 0 and (spell_name == "aegis" or spell_name == "purify" or spell_name == "rally") then
            new_position = math.max(1, i - defensive_boost)
        end

        -- Auradin-specific dynamic adjustments
        if build_index == 13 then
            -- Emergency: If Faith critically low, prioritize Rally above everything
            if faith_current < (faith_max * 0.2) and spell_name == "rally" then
                new_position = 3  -- Right after evade spells
            end

            -- Emergency: If health critical, prioritize Aegis immediately
            if health_percent < 25 and spell_name == "aegis" then
                new_position = 2  -- Right after evade
            end

            -- Boost Condemn if we need to pull enemies into aura range
            -- (This would require enemy position data to implement fully)
        end

        adjusted_priorities[new_position] = adjusted_priorities[new_position] or {}
        table.insert(adjusted_priorities[new_position], spell_name)
    end

    -- Flatten the adjusted priorities
    local final_priorities = {}
    for i = 1, #base_priorities do
        if adjusted_priorities[i] then
            for _, spell_name in ipairs(adjusted_priorities[i]) do
                table.insert(final_priorities, spell_name)
            end
        end
    end

    return final_priorities
end

-- Main function that applies all adjustments
local function get_spell_priority(build_index)
    local base_priorities = get_base_spell_priority(build_index)
    local item_adjusted = adjust_priorities_for_items(base_priorities)
    return apply_dynamic_adjustments(item_adjusted, build_index)
end

return get_spell_priority
