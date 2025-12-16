-- To modify spell priority, edit the priority tables below.
-- The function returns the appropriate priority list based on build_index.
-- 0: Default, 1: Judgement Nuke Paladin

local function get_spell_priority(build_index)
    if build_index == 1 then  -- Judgement Nuke Paladin
        return {
            -- High priority for Judgement chain: mark, pop, auras, mobility, ultimate
            "brandish",  -- Mark enemies with Judgement
            "blessed_shield",  -- Pop Judgement for damage
            "defiance_aura",  -- Defensive aura
            "fanaticism_aura",  -- Offensive aura
            "falling_star",  -- Mobility
            "fortress",  -- Ultimate for damage and immunity

            -- Other defensives and auras
            "holy_light_aura",
            "rally",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "purify",

            -- Other main damage abilities
            "blessed_hammer",
            "condemn",
            "zeal",
            "divine_lance",
            "arbiter_of_justice",

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
            -- Blessed Hammer spam with auras and mobility
            "arbiter_of_justice",  -- Ultimate (High priority)
            "falling_star",  -- Mobility/Damage (High priority)
            "fanaticism_aura",  -- Attack speed aura
            "defiance_aura",  -- Defensive aura
            "blessed_hammer",  -- Main damage skill (Spender)
            "rally",  -- Movement speed

            -- Other defensives and auras
            "holy_light_aura",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

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
            -- Arbiter focused with mobility and auras
            "arbiter_of_justice",  -- Main ultimate
            "falling_star",  -- Mobility
            "defiance_aura",  -- Defensive aura
            "holy_light_aura",  -- Healing aura
            "fanaticism_aura",  -- Attack speed aura
            "aegis",  -- Ultimate

            -- Other defensives and auras
            "rally",

            -- Other ultimates
            "zenith",
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
            "advance",
            "shield_charge",

            -- Filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    elseif build_index == 4 then  -- Blessed Shield (Captain America)
        return {
            -- Blessed Shield focused with auras and mobility
            "blessed_shield",  -- Main damage skill
            "fanaticism_aura",  -- Attack speed aura
            "defiance_aura",  -- Defensive aura
            "rally",  -- Movement speed
            "falling_star",  -- Mobility
            "holy_bolt",  -- Filler

            -- Other defensives and auras
            "holy_light_aura",

            -- Ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",
            "arbiter_of_justice",

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
            "clash",
            "consecration",
        }
    elseif build_index == 5 then  -- Shield Bash Valkyrie
        return {
            -- Shield bash focused with charge and auras
            "clash",  -- Shield bash
            "shield_charge",  -- Shield charge
            "defiance_aura",  -- Defensive aura
            "fanaticism_aura",  -- Attack speed aura
            "rally",  -- Movement speed
            "falling_star",  -- Mobility

            -- Other defensives and auras
            "holy_light_aura",

            -- Ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",
            "arbiter_of_justice",

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
            -- Mobility and ultimate focused
            "falling_star",  -- Wing strikes mobility
            "arbiter_of_justice",  -- Ultimate
            "blessed_hammer",  -- Damage
            "defiance_aura",  -- Defensive aura
            "fanaticism_aura",  -- Attack speed aura
            "rally",  -- Movement speed

            -- Other defensives and auras
            "holy_light_aura",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",

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
            -- Evade focused with Blessed Hammer spam
            "evade",  -- Evade for mobility and damage
            "blessed_hammer",  -- Main damage skill (Spender)
            "fanaticism_aura",  -- Attack speed aura
            "defiance_aura",  -- Defensive aura
            "consecration",  -- AOE damage and healing

            -- Other defensives and auras
            "holy_light_aura",

            -- Other ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "aegis",
            "fortress",
            "purify",
            "arbiter_of_justice",

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
            "rally",
        }
    elseif build_index == 8 then  -- Arbiter Evade
        return {
            -- Arbiter with evade for high mobility and ultimate spam
            "evade",  -- Evade for mobility
            "arbiter_of_justice",  -- Main ultimate
            "falling_star",  -- Mobility/Damage
            "defiance_aura",  -- Defensive aura
            "holy_light_aura",  -- Healing aura
            "fanaticism_aura",  -- Attack speed aura

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
    else  -- Default build
        return {
            -- defensives and auras
            "holy_light_aura",
            "defiance_aura",
            "fanaticism_aura",
            "rally",

            -- ultimates
            "zenith",
            "heavens_fury",
            "spear_of_the_heavens",
            "falling_star",
            "aegis",
            "fortress",
            "purify",

            -- main damage abilities
            "blessed_hammer",
            "condemn",
            "blessed_shield",
            "zeal",
            "divine_lance",
            "brandish",
            "arbiter_of_justice",

            -- mobility
            "advance",
            "shield_charge",

            -- filler abilities
            "holy_bolt",
            "clash",
            "consecration",
        }
    end
end

return get_spell_priority
