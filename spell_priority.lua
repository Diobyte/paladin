-- Paladin Rotation Priority - Optimized for MAX DPS (D4 Season 11)
--
-- =====================================================
-- MAX DPS ROTATION PHILOSOPHY:
-- =====================================================
-- 1. BUFFS FIRST: Auras provide multiplicative damage bonuses - always maintain
-- 2. ULTIMATES ON CD: Highest damage per cast - use immediately when available
-- 3. BURST COOLDOWNS: High-damage cooldown abilities weave between spam
-- 4. CORE SPAM: Primary damage dealer - spam as fast as possible
-- 5. GENERATORS ONLY WHEN NEEDED: Spell logic checks resource threshold
--
-- The key insight: Each spell's logics() function handles its OWN conditions
-- (resource checks, range checks, enemy counts). Priority order just determines
-- which spell gets CHECKED first - not which spell CASTS first.
--
-- RESOURCE SYSTEM (Faith):
-- Generators: Clash (20), Rally (22), Advance (18), Holy Bolt (16), Brandish (14)
-- Spenders: Blessed Hammer (10), Zeal (20), Divine Lance (25), Blessed Shield (28)
--
-- INTERNAL COOLDOWN SYSTEM:
-- After ANY spell casts, it goes on internal cooldown. This allows the next
-- priority spell to cast, creating natural weaving. Example:
-- Hammer → (hammer on 0.15s ICD) → Falling Star → (FS on 1.5s ICD) → Hammer → etc.

local spell_priority = {
    -- =====================================================
    -- TIER 1: BUFF MAINTENANCE (Multiplicative DPS)
    -- Check first - only cast when buff expired (handled in spell logic)
    -- =====================================================
    "fanaticism_aura",      -- Offensive aura - Attack Speed (HUGE DPS increase)
    "defiance_aura",        -- Defensive aura - Damage Reduction (survival)
    "holy_light_aura",      -- Healing aura - Life Regeneration (sustain)
    
    -- =====================================================
    -- TIER 2: ULTIMATE ABILITIES (Highest Damage Per Cast)
    -- Game handles actual cooldown - we just check if available
    -- =====================================================
    "arbiter_of_justice",   -- Ultimate (CD: 120s) - 600% + Arbiter form 20s
    "heavens_fury",         -- Ultimate (CD: 30s) - 200%/s AoE + seeking beams
    "zenith",               -- Ultimate (CD: 25s) - 450% cleave + 400% recast
    
    -- =====================================================
    -- TIER 3: BURST COOLDOWNS (High DPE - Damage Per Execute)
    -- These deal massive damage but have cooldowns
    -- Weave between core spam for maximum burst windows
    -- =====================================================
    "falling_star",         -- Valor (CD: 12s) - 320% total (80+240), mobility
    "spear_of_the_heavens", -- Justice (CD: 14s) - 280% total + knockdown
    "condemn",              -- Justice (CD: 15s) - 240% + pull + stun (setup)
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
    -- TIER 6: RESOURCE GENERATORS (Use When Faith Depleted)
    -- Each spell's logics() has resource_threshold check
    -- Only casts when Faith is below threshold
    -- =====================================================
    "clash",                -- Basic (Gen: 20) - Shield bash, highest gen
    "rally",                -- Valor (Gen: 22) - Move speed buff + Faith
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
