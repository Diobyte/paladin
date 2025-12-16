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

            -- Arbiter focused with mobility and auras - ULTIMATE SPAM BUILD
            "arbiter_of_justice",
            "falling_star",
            "fanaticism_aura",
            "defiance_aura",
            "holy_light_aura",
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

-- Main function that applies item adjustments
local function get_spell_priority(build_index)
    local base_priorities = get_base_spell_priority(build_index)
    return adjust_priorities_for_items(base_priorities)
end

return get_spell_priority
