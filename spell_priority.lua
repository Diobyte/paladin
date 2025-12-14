-- Paladin Rotation Priority - Hammerkuna Build (D4 Season 11)
--
-- HAMMERKUNA BUILD ROTATION:
-- The core mechanic is SPAM Blessed Hammer constantly while weaving in other abilities.
-- Blessed Hammer creates spiraling hammers around you that deal massive AoE damage.
-- Falling Star provides mobility and burst AoE.
-- Auras provide passive buffs (only recast when expired - handled by spell logic).
--
-- KEY INSIGHT: Unlike other builds where you prioritize cooldowns first,
-- Hammerkuna wants to SPAM blessed_hammer as the primary damage dealer.
-- Other spells should only cast when their conditions are met AND not block hammer spam.

local spell_priority = {
    -- Priority 1: Auras (buff maintenance)
    -- These only cast when buff expires (handled in spell logic)
    -- Check them first so buffs stay active
    "fanaticism_aura",      -- Attack speed/damage buff
    "defiance_aura",        -- Damage reduction buff  
    "holy_light_aura",      -- Healing buff
    
    -- Priority 2: Ultimate abilities (use when available on tough packs)
    -- These have game-enforced cooldowns, so safe to check
    "arbiter_of_justice",   -- Judicator Ultimate
    "heavens_fury",         -- AoE around player + seeking beams
    "zenith",               -- Zealot Ultimate - melee AoE cleave
    
    -- Priority 3: CORE SPAM SKILL - Blessed Hammer (THE MAIN SKILL)
    -- This is the heart of Hammerkuna - spam constantly
    "blessed_hammer",
    "blessed_shield",       -- Alternative core: bouncing shield (requires shield)
    
    -- Priority 4: Mobility/Gap closer (use for engaging or repositioning)
    "falling_star",         -- Leap AoE - main mobility skill
    "shield_charge",        -- Charge through enemies
    "advance",              -- Lunge forward
    
    -- Priority 5: Burst abilities (use between hammer spam when available)
    "spear_of_the_heavens", -- Ranged AoE knockdown
    "condemn",              -- Pull enemies in + stun
    "divine_lance",         -- Melee impale
    "brandish",             -- Melee cleave
    "consecration",         -- Ground heal + damage
    
    -- Priority 6: Utility buffs
    "rally",                -- Group buff
    
    -- Priority 7: Basic attacks / Resource generators (LAST RESORT)
    -- Only use these if out of resource or nothing else available
    "zeal",                 -- Melee multi-strike (Faith generator)
    "clash",                -- Shield bash (Faith generator, requires shield)
    "holy_bolt",            -- Ranged projectile (Faith generator)
}

return spell_priority
