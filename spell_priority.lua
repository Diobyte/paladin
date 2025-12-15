-- To modify spell priority, edit the spell_priority table below.
-- The table is sorted from highest priority to lowest priority.
-- The priority is used to determine which spell to cast when multiple spells are valid to cast.

local spell_priority = {
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

return spell_priority
