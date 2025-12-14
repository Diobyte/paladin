-- Paladin Rotation Priority - Optimized for MAX DPS (D4 Season 11)
--
-- =====================================================
-- META ROTATION (Blessed Hammer / Hammerdin from maxroll.gg):
-- =====================================================
-- 1. Spam Blessed Hammer to deal damage
-- 2. Use Falling Star OR Condemn every few seconds to stay in Arbiter form
-- 3. Use Evade in Arbiter to auto-cast Blessed Hammer with Argent Veil
-- 4. Activate Fanaticism Aura, Defiance Aura and Rally as often as possible
-- 5. Use Condemn to pull enemies in
--
-- ARBITER FORM: Triggered by Falling Star or Condemn via Disciple Oath
-- This is CRITICAL for Hammerdin builds - keep Arbiter uptime high!
--
-- RESOURCE SYSTEM (Faith):
-- Generators: Clash (20), Rally (22), Advance (18), Holy Bolt (16), Brandish (14)
-- Spenders: Blessed Hammer (10), Zeal (20), Divine Lance (25), Blessed Shield (28)
--
-- INTERNAL COOLDOWN SYSTEM:
-- After ANY spell casts, it goes on internal cooldown. This allows the next
-- priority spell to cast, creating natural weaving. Example:
-- Hammer → (hammer on 0.15s ICD) → Falling Star → (FS on ICD) → Hammer → etc.

local spell_priority = {
    -- =====================================================
    -- TIER 1: BUFF MAINTENANCE (Multiplicative DPS)
    -- Check first - only cast when buff expired (handled in spell logic)
    -- Meta: "Activate Fanaticism Aura, Defiance Aura and Rally as often as possible"
    -- =====================================================
    "fanaticism_aura",      -- Offensive aura - Attack Speed (HUGE DPS increase)
    "defiance_aura",        -- Defensive aura - Damage Reduction (survival)
    "holy_light_aura",      -- Healing aura - Life Regeneration (sustain)
    "rally",                -- Meta: Use often! Move speed buff + 22 Faith (3 charges)
    
    -- =====================================================
    -- TIER 2: ULTIMATE ABILITIES (Highest Damage Per Cast)
    -- Game handles actual cooldown - we just check if available
    -- =====================================================
    "arbiter_of_justice",   -- Ultimate (CD: 120s) - 600% + Arbiter form 20s
    "heavens_fury",         -- Ultimate (CD: 30s) - 200%/s AoE + seeking beams
    "zenith",               -- Ultimate (CD: 25s) - 450% cleave + 400% recast
    
    -- =====================================================
    -- TIER 3: ARBITER TRIGGERS + BURST (Critical for Hammerdin)
    -- Falling Star & Condemn trigger Arbiter form via Disciple Oath
    -- Use these frequently (every few seconds) to maintain Arbiter!
    -- =====================================================
    "falling_star",         -- Valor (CD: 12s) - 320% total, mobility, ARBITER TRIGGER
    "spear_of_the_heavens", -- Justice (CD: 14s) - 280% total + knockdown
    "condemn",              -- Justice (CD: 15s) - 240% + pull + stun, ARBITER TRIGGER
    "consecration",         -- Justice (CD: 18s) - 75%/s for 6s = 450% total + heal
    
    -- =====================================================
    -- TIER 4: CORE SPAM SKILL (Primary DPS)
    -- This is the bread and butter - spam constantly
    -- Short internal cooldown allows burst abilities to weave in
    -- =====================================================
    "blessed_hammer",       -- Core (Cost: 10) - 115% AoE spiral, SPAM THIS
    
    -- =====================================================
    -- TIER 5: ALTERNATIVE CORE SPENDERS (Build Variants)
    -- These have higher cost but different use cases
    -- Their logics() checks appropriate conditions
    -- =====================================================
    "blessed_shield",       -- Core (Cost: 28) - 216% + 3x ricochet, shield builds
    "zeal",                 -- Core (Cost: 20) - 140% melee combo, zealot builds
    "divine_lance",         -- Core (Cost: 25) - 180% impale, mobility builds
    
    -- =====================================================
    -- TIER 6: RESOURCE GENERATORS
    -- Generators: Only cast when Faith is LOW (below threshold)
    -- Rally moved to Tier 1 as per meta: "activate Rally as often as possible"
    -- =====================================================
    "clash",                -- Basic (Gen: 20) - Shield bash, highest gen
    "advance",              -- Basic (Gen: 18) - Lunge, also gap closer
    "holy_bolt",            -- Basic (Gen: 16) - Ranged option
    "brandish",             -- Basic (Gen: 14) - Melee arc, backup
    
    -- =====================================================
    -- TIER 7: MOBILITY (Engage/Disengage)
    -- Lower priority - used for positioning, not DPS
    -- =====================================================
    "shield_charge",        -- Valor (CD: 10s) - Gap closer with DR
}

return spell_priority
