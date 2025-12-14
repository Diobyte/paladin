-- Paladin Spell Data for Diablo 4 Season 11
-- Class ID: 7 (added in Lord of Hatred expansion)
-- Class Resource: Faith
-- Primary Stat: Strength
-- Damage Types: Holy, Physical
-- Skill Groups: Basic, Core, Aura, Valor, Justice, Ultimate
-- Unique Mechanic: Oaths (Disciple, Judicator, Juggernaut, Zealot)
-- 
-- Spell IDs verified from Wowhead Diablo 4 database (Dec 2025)
-- https://www.wowhead.com/diablo-4/skills/paladin
--
-- TARGETING GUIDE:
-- cast_spell.self(spell_id)        - Self-cast spells (auras, ground AoE around player)
-- cast_spell.target(unit, spell_id, delay, is_channeled) - Target a unit directly (melee, homing)
-- cast_spell.position(spell_id, pos, delay) - Cast at ground position (AoE, skillshots)

local spell_data = {
    -- =====================================================
    -- BASIC SKILLS (Resource Generators)
    -- Generate Faith on hit
    -- =====================================================
    holy_bolt = {
        spell_id = 2174078,  -- Verified: wowhead.com/diablo-4/skill/holy-bolt-2174078
        category = "basic",
        cast_type = "target",    -- Ranged projectile at target
        damage_type = "holy",
        faith_gen = 16,
        description = "Throw a Holy hammer dealing 90% damage. Generates 16 Faith.",
        -- Targeting: cast_spell.target(target, spell_id) - projectile homes to target
    },
    zeal = {
        spell_id = 2132824,  -- Verified: wowhead.com/diablo-4/skill/zeal-2132824
        category = "core",       -- CORE SKILL (Spender)
        cast_type = "target",    -- Melee multi-strike at target
        damage_type = "physical",
        faith_cost = 20,
        description = "Strike enemies with blinding speed, 80% + 3x20% damage. Costs 20 Faith.",
        -- Targeting: cast_spell.target(target, spell_id) - requires melee range
    },
    advance = {
        spell_id = 2329865,  -- Verified: wowhead.com/diablo-4/skill/advance-2329865
        category = "basic",
        cast_type = "position",  -- Lunge forward to position
        damage_type = "physical",
        faith_gen = 18,
        description = "Advance forward with your weapon dealing 105% damage. Generates 18 Faith.",
        is_mobility = true,
        -- Targeting: cast_spell.position(spell_id, target_pos) - dashes to location
    },
    clash = {
        spell_id = 2097465,  -- Clash - Shield Bash basic skill
        category = "basic",
        cast_type = "target",    -- Melee shield bash at target
        damage_type = "physical",
        faith_gen = 20,
        description = "Strike with weapon and shield dealing 115% damage. Generates 20 Faith. Requires shield.",
        requires_shield = true,
        -- Targeting: cast_spell.target(target, spell_id) - requires melee range
    },
    
    -- =====================================================
    -- CORE SKILLS (Main Damage Spenders)
    -- Cost Faith to deal damage
    -- =====================================================
    blessed_hammer = {
        spell_id = 2107555,  -- Verified: wowhead.com/diablo-4/skill/blessed-hammer-2107555
        category = "core",
        cast_type = "self",      -- Spirals outward FROM player
        damage_type = "holy",
        faith_cost = 10,
        description = "Throw a Blessed Hammer that spirals out, 115% damage",
        -- Targeting: cast_spell.self(spell_id) - hammers spiral from player position
    },
    blessed_shield = {
        spell_id = 2082021,  -- Blessed Shield - Extended melee shield throw
        category = "core",
        cast_type = "target",    -- Extended melee skill (5.5-6.0 range)
        damage_type = "holy",
        faith_cost = 28,
        cast_range = 6.0,
        description = "Hurl your shield with Holy energy dealing 216% damage, ricochets up to 3 times. Extended melee range. Requires shield.",
        requires_shield = true,
        -- Targeting: cast_spell.target(target, spell_id) - extended melee, ricochets to nearby enemies
    },
    divine_lance = {
        spell_id = 2120228,  -- Verified: wowhead.com/diablo-4/skill/divine-lance-2120228
        category = "core",
        cast_type = "target",    -- Impale target with lance
        damage_type = "holy",
        faith_cost = 25,
        is_mobility = true,
        description = "Impale enemies with a heavenly lance, stabbing 2x90% damage",
        -- Targeting: cast_spell.target(target, spell_id) - melee/short range skillshot
    },
    brandish = {
        spell_id = 2265693,  -- Verified: wowhead.com/diablo-4/skill/brandish-2265693
        category = "basic",      -- Basic skill (generator)
        cast_type = "target",    -- Melee swing at target
        damage_type = "holy",
        faith_gen = 14,
        description = "Brandish the Light, unleashing an arc dealing 75% damage. Generates 14 Faith.",
        -- Targeting: cast_spell.target(target, spell_id) - requires melee range
    },
    
    -- =====================================================
    -- AURA SKILLS (Maintained Buffs)
    -- Toggle on for persistent effects, duration-based
    -- =====================================================
    defiance_aura = {
        spell_id = 2187578,  -- Verified via builds
        category = "aura",
        cast_type = "self",      -- Self-cast buff
        duration = 12.0,
        description = "Defensive aura granting damage reduction",
        -- Targeting: cast_spell.self(spell_id) - buff around player
    },
    fanaticism_aura = {
        spell_id = 2187741,  -- Verified: wowhead.com/diablo-4/skill/fanaticism-aura-2187741
        category = "aura",
        cast_type = "self",      -- Self-cast buff
        duration = 12.0,
        description = "Offensive aura granting attack speed",
        -- Targeting: cast_spell.self(spell_id) - buff around player
    },
    holy_light_aura = {
        spell_id = 2297097,  -- Verified: wowhead.com/diablo-4/skill/holy-light-aura-2297097
        category = "aura",
        cast_type = "self",      -- Self-cast buff
        duration = 12.0,
        description = "Healing aura granting life regeneration",
        -- Targeting: cast_spell.self(spell_id) - buff around player
    },
    
    -- =====================================================
    -- VALOR SKILLS (Utility/Mobility/Defensive)
    -- =====================================================
    shield_charge = {
        spell_id = 2466077,  -- Verified: wowhead.com/diablo-4/skill/shield-charge-2466077
        category = "valor",
        cast_type = "position",  -- Charge toward position
        damage_type = "physical",
        cooldown = 10.0,
        is_channeled = true,
        requires_shield = true,
        description = "Charge with shield pushing enemies, 10% DR + 90% damage while channeling. Requires shield.",
        -- Targeting: cast_spell.position(spell_id, target_pos) - charge in direction
    },
    rally = {
        spell_id = 2303677,  -- Verified via builds
        category = "valor",
        cast_type = "self",      -- Self-cast buff
        charges = 3,
        cooldown = 16.0,
        faith_gen = 22,
        description = "Rally forth gaining 20% Move Speed for 8s and generate 22 Faith. 3 charges.",
        -- Targeting: cast_spell.self(spell_id) - instant self-buff
    },
    
    -- =====================================================
    -- JUSTICE SKILLS (Damage/Control)
    -- Heavy hitters with crowd control
    -- =====================================================
    spear_of_the_heavens = {
        spell_id = 2100457,  -- Verified: wowhead.com/diablo-4/skill/spear-of-the-heavens-2100457
        category = "justice",
        cast_type = "position",  -- Ground-targeted AoE
        damage_type = "holy",
        cooldown = 14.0,
        description = "Rain down 4 heavenly spears, 160% + 120% burst damage, Knockdown 1.5s",
        -- Targeting: cast_spell.position(spell_id, target_pos) - AoE at location
    },
    falling_star = {
        spell_id = 2106904,  -- Verified via builds
        category = "valor",      -- Changed from justice - it's a Valor mobility skill
        cast_type = "position",  -- Leap to position
        damage_type = "holy",
        cooldown = 12.0,
        is_mobility = true,
        description = "Soar with angelic wings and dive, 80% takeoff + 240% landing damage.",
        -- Targeting: cast_spell.position(spell_id, target_pos) - leap to location
    },
    condemn = {
        spell_id = 2226109,  -- Verified: wowhead.com/diablo-4/skill/condemn-2226109
        category = "justice",
        cast_type = "self",      -- AoE pulls to player after delay
        damage_type = "holy",
        cooldown = 15.0,
        description = "Harness Light, Pull enemies in after 1.5s, Stun, 240% damage",
        -- Targeting: cast_spell.self(spell_id) - centered on player
    },
    consecration = {
        spell_id = 2283781,  -- Verified: wowhead.com/diablo-4/skill/consecration-2283781
        category = "justice",
        cast_type = "self",      -- Ground AoE at player location
        damage_type = "holy",
        cooldown = 18.0,
        duration = 6.0,
        is_defensive = true,
        description = "Bathe in Light for 6s, Heal 4% Max Life/s, damage 75%/s",
        -- Targeting: cast_spell.self(spell_id) - ground effect at player
    },
    
    -- =====================================================
    -- ULTIMATE SKILLS
    -- High impact, long cooldowns
    -- =====================================================
    arbiter_of_justice = {
        spell_id = 2297125,  -- Verified: wowhead.com/diablo-4/skill/arbiter-of-justice-2297125
        category = "ultimate",
        cast_type = "position",  -- Land at target position
        damage_type = "holy",
        cooldown = 120.0,
        description = "Ascend and crash as Arbiter for 20s, 600% landing damage.",
        -- Targeting: cast_spell.position(spell_id, target_pos) - leap to location
    },
    heavens_fury = {
        spell_id = 2273081,  -- Verified: wowhead.com/diablo-4/skill/heavens-fury-2273081
        category = "ultimate",
        cast_type = "self",      -- AoE around player then seeking beams
        damage_type = "holy",
        cooldown = 30.0,
        description = "Grasp Light, 200%/s around you, releases seeking beams 60%/hit for 7s",
        -- Targeting: cast_spell.self(spell_id) - centered on player
    },
    zenith = {
        spell_id = 2302974,  -- Verified: wowhead.com/diablo-4/skill/zenith-2302974
        category = "ultimate",
        cast_type = "self",      -- Cleave around player
        damage_type = "physical",
        cooldown = 25.0,
        description = "Divine sword cleave 450%, recast for 400% + Knockdown 2s",
        -- Targeting: cast_spell.self(spell_id) - melee AoE around player
    },
    
    -- =====================================================
    -- COMMON SKILLS
    -- =====================================================
    evade = {
        spell_id = 337031,
        category = "common",
        cast_type = "position",  -- Evade to position
        is_mobility = true,
        description = "Dodge roll to avoid damage",
        -- Targeting: cast_spell.position(spell_id, safe_pos) - dash to safety
    },
    
    -- =====================================================
    -- ENEMY DEBUFFS/BUFFS (for targeting logic)
    -- =====================================================
    enemies = {
        damage_resistance = {
            spell_id = 1094180,
            buff_ids = {
                provider = 2771801864,
                receiver = 2182649012
            }
        }
    }
}

return spell_data
