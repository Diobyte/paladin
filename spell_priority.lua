-- To modify spell priority, edit the priority tables below.
-- The function returns the appropriate priority list based on build_index.
-- 0: Default, 1: Judgement Nuke Paladin

-- Function to analyze equipped items and adjust spell priorities
local function adjust_priorities_for_items(base_priorities)
    -- Get equipped items to analyze stats
    local equipped_items = get_equipped_items()
    local attack_speed_total = 0
    local cdr_total = 0
    local crit_damage_total = 0
    local resource_gen_total = 0

    -- Analyze each equipped item for relevant stats
    for _, item in ipairs(equipped_items) do
        if item then
            -- Check for attack speed (reduces aura priority)
            local attack_speed = item:get_attack_speed() or 0
            attack_speed_total = attack_speed_total + attack_speed

            -- Check for cooldown reduction (increases ultimate priority)
            local cdr = item:get_cooldown_reduction() or 0
            cdr_total = cdr_total + cdr

            -- Check for critical hit damage
            local crit_damage = item:get_critical_hit_damage() or 0
            crit_damage_total = crit_damage_total + crit_damage

            -- Check for resource generation
            local resource_gen = item:get_resource_generation() or 0
            resource_gen_total = resource_gen_total + resource_gen
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

-- Function to get base spell priority (without item adjustments)
local function get_base_spell_priority(build_index)
    if build_index == 1 then  -- Judgement Nuke Paladin
        return {
            -- High priority for Judgement chain: mark, pop, auras, mobility, ultimate
            "brandish",  -- Mark enemies with Judgement (HIGH PRIORITY)
            "blessed_shield",  -- Pop Judgement for massive damage (HIGH PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "falling_star",  -- Mobility for positioning (HIGH PRIORITY)
            "arbiter_of_justice",  -- Ultimate spam for DPS (HIGH PRIORITY)

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

            -- Other main damage abilities
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
            -- Blessed Hammer spam with auras and mobility - META AOE BUILD
            "blessed_hammer",  -- Main damage skill (HIGHEST PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "falling_star",  -- Mobility for kiting (HIGH PRIORITY)
            "rally",  -- Movement speed for positioning (HIGH PRIORITY)
            "arbiter_of_justice",  -- Ultimate for DPS boost (HIGH PRIORITY)

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Other defensives and auras
            "holy_light_aura",

            -- Other main damage abilities
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
            -- Arbiter focused with mobility and auras - ULTIMATE SPAM BUILD
            "arbiter_of_justice",  -- Main ultimate (HIGHEST PRIORITY)
            "falling_star",  -- Mobility for positioning (HIGH PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "holy_light_aura",  -- Healing aura (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)

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

            -- Mobility
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 4 then  -- Blessed Shield (Captain America)
        return {
            -- Blessed Shield focused with auras and mobility - SINGLE TARGET BUILD
            "blessed_shield",  -- Main damage skill (HIGHEST PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)
            "falling_star",  -- Mobility (HIGH PRIORITY)
            "arbiter_of_justice",  -- Ultimate spam (HIGH PRIORITY)

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Other defensives and auras
            "holy_light_aura",

            -- Other main damage abilities
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
            -- Shield bash focused with charge and auras - MELEE BUILD
            "clash",  -- Shield bash (HIGHEST PRIORITY)
            "shield_charge",  -- Shield charge (HIGH PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)
            "falling_star",  -- Mobility (HIGH PRIORITY)

            -- Ultimates
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
            -- Mobility and ultimate focused - HIGH MOBILITY BUILD
            "falling_star",  -- Wing strikes mobility (HIGHEST PRIORITY)
            "arbiter_of_justice",  -- Ultimate (HIGH PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)
            "blessed_hammer",  -- AOE damage (HIGH PRIORITY)

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Other defensives and auras
            "holy_light_aura",

            -- Other main damage abilities
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
            -- Evade focused with Blessed Hammer spam - META EVADE BUILD
            "evade",  -- Evade for mobility and damage (HIGHEST PRIORITY)
            "blessed_hammer",  -- Main damage skill (HIGH PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "consecration",  -- AOE damage and healing (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)

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

            -- Other main damage abilities
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
            "evade",  -- Evade for mobility (HIGHEST PRIORITY)
            "arbiter_of_justice",  -- Main ultimate (HIGH PRIORITY)
            "falling_star",  -- Additional mobility (HIGH PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "holy_light_aura",  -- Healing aura (HIGH PRIORITY)

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
            -- Core auras for all builds
            "fanaticism_aura",  -- Attack speed (HIGHEST PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "holy_light_aura",  -- Healing aura (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)

            -- High priority ultimates and mobility
            "arbiter_of_justice",  -- Ultimate spam
            "falling_star",  -- Mobility
            "blessed_hammer",  -- AOE damage

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
    elseif build_index == 9 then  -- Heaven's Fury Spam
        return {
            -- Heaven's Fury ultimate spam - HIGH DAMAGE BUILD
            "heavens_fury",  -- Main ultimate (HIGHEST PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)
            "falling_star",  -- Mobility (HIGH PRIORITY)
            "blessed_hammer",  -- AOE damage (HIGH PRIORITY)

            -- Other ultimates
            "arbiter_of_justice",
            "zenith",
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
            -- Spear of the Heavens focused - RANGED ULTIMATE BUILD
            "spear_of_the_heavens",  -- Main ultimate (HIGHEST PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)
            "falling_star",  -- Mobility (HIGH PRIORITY)
            "blessed_hammer",  -- AOE damage (HIGH PRIORITY)

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
    elseif build_index == 11 then  -- Condemn Spam
        return {
            -- Condemn focused spam - HIGH SINGLE TARGET DPS
            "condemn",  -- Main damage skill (HIGHEST PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)
            "falling_star",  -- Mobility (HIGH PRIORITY)
            "arbiter_of_justice",  -- Ultimate spam (HIGH PRIORITY)

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

            -- Other defensives and auras
            "holy_light_aura",

            -- Other main damage abilities
            "blessed_hammer",
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
    elseif build_index == 12 then  -- Zenith Aegis Tank
        return {
            -- Zenith and Aegis focused - TANKY ULTIMATE BUILD
            "zenith",  -- Ultimate (HIGHEST PRIORITY)
            "aegis",  -- Ultimate (HIGH PRIORITY)
            "fanaticism_aura",  -- Attack speed aura (HIGH PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "holy_light_aura",  -- Healing aura (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)

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
    else  -- Default build (build_index == 0 or any other value)
        return {
            -- Core auras for all builds
            "fanaticism_aura",  -- Attack speed (HIGHEST PRIORITY)
            "defiance_aura",  -- Defensive aura (HIGH PRIORITY)
            "holy_light_aura",  -- Healing aura (HIGH PRIORITY)
            "rally",  -- Movement speed (HIGH PRIORITY)

            -- High priority ultimates and mobility
            "arbiter_of_justice",  -- Ultimate spam
            "falling_star",  -- Mobility
            "blessed_hammer",  -- AOE damage

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

-- Main function that applies item adjustments
local function get_spell_priority(build_index)
    local base_priorities = get_base_spell_priority(build_index)
    return adjust_priorities_for_items(base_priorities)
end

return get_spell_priority
