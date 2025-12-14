-- To modify spell priority, edit the spell_priority table below.
-- The table is sorted from highest priority to lowest priority.
-- The priority is used to determine which spell to cast when multiple spells are valid to cast.
--
-- Paladin Rotation Logic (Season 11):
-- 1. Ultimate abilities - high damage, long cooldowns, save for big packs/elites
-- 2. Justice abilities - crowd control and burst damage
-- 3. Auras - maintained buffs, only recast when duration expires (handled by spell logic)
-- 4. Core damage - main damage output
-- 5. Gap closers - for engaging distant enemies
-- 6. Defensive - healing/damage reduction
-- 7. Basic attacks - resource generators/fillers
--
-- Targeting Types (see spell_data.lua):
-- cast_spell.self()     - Self-cast spells (auras, AoE around player)
-- cast_spell.target()   - Direct target (melee, homing projectiles)
-- cast_spell.position() - Ground position (AoE, skillshots, charges)

local spell_priority = {
    -- Priority 1: Ultimate abilities (powerful cooldowns)
    -- Judicator Ultimate
    "arbiter_of_justice",   -- cast_spell.target() - seeking AoE damage
    "heavens_fury",         -- cast_spell.self()   - AoE around player + seeking beams
    -- Zealot Ultimate
    "zenith",               -- cast_spell.self()   - melee AoE cleave + knockdown
    
    -- Priority 2: Justice abilities (burst damage + crowd control)
    "falling_star",         -- cast_spell.position() - leap AoE
    "spear_of_the_heavens", -- cast_spell.position() - ranged AoE knockdown
    "condemn",              -- cast_spell.self()   - pull enemies in + stun
    
    -- Priority 3: Core damage skills
    "divine_lance",         -- cast_spell.target() - melee impale
    "blessed_hammer",       -- cast_spell.self()   - spiral AoE
    "brandish",             -- cast_spell.target() - melee cleave
    
    -- Priority 4: Gap closers / Mobility (for engaging)
    "shield_charge",        -- cast_spell.position() - channeled charge
    "advance",              -- cast_spell.position() - lunge forward
    "evade",                -- cast_spell.position() - dodge roll (defensive)
    
    -- Priority 5: Defensive / Healing
    "consecration",         -- cast_spell.self() - ground heal + damage
    
    -- Priority 6: Auras (buff maintenance - spell logic handles recast timing)
    -- These will only cast when their duration is expiring
    "fanaticism_aura",      -- cast_spell.self() - attack speed/damage buff
    "defiance_aura",        -- cast_spell.self() - damage reduction buff
    "holy_light_aura",      -- cast_spell.self() - healing buff
    "rally",                -- cast_spell.self() - utility buff
    
    -- Priority 7: Basic attacks / Filler / Resource generator (lowest priority)
    "zeal",                 -- cast_spell.target() - melee multi-strike (Faith generator)
    "holy_bolt",            -- cast_spell.target() - ranged projectile (Faith generator)
}

return spell_priority
