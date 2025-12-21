---@diagnostic disable: undefined-field
-- Paladin Spell Priority Configuration
-- Defines spell casting order for all 12 paladin builds
-- Build indices: 0=default, 1-11=specialized builds

local my_utility = require("my_utility/my_utility");
local spell_data = require("my_utility/spell_data");
local actors_manager = require("actors_manager");

-- Helper to determine spell tier for sorting logic
-- Tier 1: Critical/Survival
-- Tier 2: Buffs/Auras
-- Tier 3: Ultimates
-- Tier 4: Mobility/Engage
-- Tier 5: Spenders/Core
-- Tier 6: Generators/Basic
-- Tier 7: Utility/Other
local function get_spell_tier(spell_name)
    local tiers = {
        paladin_evade = 1,
        evade = 1,
        aegis = 1, -- Defensive ultimate, high priority if low health

        fanaticism_aura = 2,
        defiance_aura = 2,
        holy_light_aura = 2,
        rally = 2,

        arbiter_of_justice = 3,
        heavens_fury = 3,
        zenith = 3,
        spear_of_the_heavens = 3,
        fortress = 3,
        purify = 3,

        falling_star = 4,
        shield_charge = 4,
        advance = 4,

        blessed_hammer = 5,
        blessed_shield = 5,
        divine_lance = 5,
        condemn = 5,
        zeal = 5, -- Core skill (Spender)

        holy_bolt = 6,
        clash = 6,
        brandish = 6,

        consecration = 7,
    }
    return tiers[spell_name] or 10 -- Default to low priority
end

-- Function to get base spell priority (without item adjustments)
-- Returns ALPHABETICAL list as requested, logic is handled in apply_dynamic_adjustments
local function get_base_spell_priority(build_index)
    -- All builds return the same alphabetical list of ALL potential spells.
    -- The dynamic logic will filter and sort them based on the build index.
    -- This satisfies "Order them in the total listing alphabetical".
    return {
        "advance",
        "aegis",
        "arbiter_of_justice",
        "blessed_hammer",
        "blessed_shield",
        "brandish",
        "clash",
        "condemn",
        "consecration",
        "defiance_aura",
        "divine_lance",
        "evade",
        "falling_star",
        "fanaticism_aura",
        "fortress",
        "heavens_fury",
        "holy_bolt",
        "holy_light_aura",
        "paladin_evade",
        "purify",
        "rally",
        "shield_bash",
        "shield_charge",
        "spear_of_the_heavens",
        "zeal",
        "zenith",
    }
end

-- Function to analyze equipped items and adjust spell priorities
local function adjust_priorities_for_items(base_priorities)
    -- Since base_priorities is now just a list of names, we don't need to reorder it here.
    -- We can just pass it through. The logic moves to apply_dynamic_adjustments.
    return base_priorities
end

-- Main logic to sort spells based on context and build
local function apply_dynamic_adjustments(base_priorities, build_index)
    local local_player = get_local_player()
    if not local_player then return base_priorities end

    local max_health = local_player:get_max_health()
    local current_health_percentage = max_health > 0 and (local_player:get_current_health() / max_health) or 1.0

    local faith_current = local_player:get_primary_resource_current()
    local faith_max = local_player:get_primary_resource_max()
    local faith_percent = faith_max > 0 and (faith_current / faith_max) or 0.0

    local enemies = actors_manager.get_enemy_npcs()
    local enemy_count = #enemies
    local closest_enemy_dist = 999
    for _, enemy in ipairs(enemies) do
        local dist = enemy:get_position():dist_to(local_player:get_position())
        if dist < closest_enemy_dist then closest_enemy_dist = dist end
    end

    -- Scoring table
    local scored_spells = {}

    for _, spell_name in ipairs(base_priorities) do
        local tier = get_spell_tier(spell_name)
        local score = (10 - tier) * 100 -- Base score: Tier 1 = 900, Tier 7 = 300

        -- 1. Survival Logic
        if current_health_percentage < 0.4 then
            if spell_name == "aegis" or spell_name == "purify" or spell_name == "fortress" then
                score = score + 1000 -- Emergency priority
            end
            if spell_name == "paladin_evade" or spell_name == "evade" then
                score = score + 500
            end
        end

        -- 2. Buff/Aura Logic
        if tier == 2 then -- Auras/Rally
            local data = spell_data[spell_name]
            if data then
                local is_active = my_utility.is_buff_active(data.spell_id, data.buff_id)
                if not is_active then
                    score = score + 500 -- High priority to activate buffs
                else
                    score = -100        -- Deprioritize if already active
                end
            end
        end

        -- 3. Resource Management
        if tier == 5 then           -- Spenders
            if faith_percent > 0.4 then
                score = score + 50  -- Boost spenders if we have faith
            else
                score = score - 200 -- Deprioritize if low faith
            end
        elseif tier == 6 then       -- Generators
            if faith_percent < 0.4 then
                score = score + 300 -- Boost generators if low faith
            end
        end

        -- 4. Mobility/Range Logic
        if tier == 4 then           -- Mobility
            if closest_enemy_dist > 6.0 then
                score = score + 200 -- Use mobility to close gap
            else
                score = score - 50  -- Don't dash if already close
            end
        end

        -- 5. Build Specific Overrides
        if build_index == 1 then -- Judgement Nuke
            if spell_name == "arbiter_of_justice" then score = score + 150 end
            if spell_name == "brandish" then score = score + 50 end
        elseif build_index == 2 then                                       -- Hammerkuna
            if spell_name == "blessed_hammer" then score = score + 250 end -- Main spam
        elseif build_index == 3 then                                       -- Arbiter
            if spell_name == "arbiter_of_justice" then score = score + 300 end
            if spell_name == "zeal" then score = score + 100 end           -- Wrath builder
        elseif build_index == 4 then                                       -- Captain America
            if spell_name == "blessed_shield" then score = score + 250 end
        elseif build_index == 5 then                                       -- Shield Bash
            if spell_name == "shield_bash" then score = score + 250 end
        elseif build_index == 6 then                                       -- Wing Strikes
            if spell_name == "falling_star" then score = score + 200 end
        elseif build_index == 7 then                                       -- Evade Hammer
            if spell_name == "blessed_hammer" then score = score + 250 end
            if spell_name == "evade" then score = score + 100 end
        elseif build_index == 8 then  -- Arbiter Evade
            if spell_name == "arbiter_of_justice" then score = score + 250 end
        elseif build_index == 9 then  -- Heaven's Fury
            if spell_name == "heavens_fury" then score = score + 250 end
        elseif build_index == 10 then -- Spear
            if spell_name == "spear_of_the_heavens" then score = score + 250 end
        elseif build_index == 11 then -- Zenith Tank
            if spell_name == "zenith" then score = score + 250 end
            if spell_name == "aegis" then score = score + 100 end
        elseif build_index == 12 then                                       -- Auradin
            if spell_name == "holy_light_aura" then score = score + 300 end -- Critical
            if spell_name == "condemn" then score = score + 100 end         -- Pull
            if spell_name == "blessed_hammer" then score = score + 100 end  -- Proc
        end

        -- 6. AOE Logic
        if enemy_count >= 3 then
            if spell_name == "blessed_hammer" or spell_name == "heavens_fury" or spell_name == "consecration" or spell_name == "condemn" then
                score = score + 100
            end
        end

        table.insert(scored_spells, { name = spell_name, score = score })
    end

    -- Sort by score descending
    table.sort(scored_spells, function(a, b)
        return a.score > b.score
    end)

    -- Extract names
    local result = {}
    for _, item in ipairs(scored_spells) do
        table.insert(result, item.name)
    end

    if rawget(_G, 'DEBUG_SPELL_PRIORITY') then
        print('DEBUG: Sorted Priority for Build ' .. tostring(build_index))
        for i, name in ipairs(result) do
            print(string.format("%d. %s (Score: %d)", i, name, scored_spells[i].score))
        end
    end

    return result
end

-- Main function that applies all adjustments
local function get_spell_priority(build_index)
    local base_priorities = get_base_spell_priority(build_index)
    -- adjust_priorities_for_items is now a pass-through or can be removed if logic is fully in apply_dynamic_adjustments
    -- Keeping it for API compatibility if needed, but logic is moved.
    return apply_dynamic_adjustments(base_priorities, build_index)
end

-- Expose internal helpers for unit testing via a callable table
local api = {}
setmetatable(api, { __call = function(self, build_index) return get_spell_priority(build_index) end })
api.get_base_spell_priority = get_base_spell_priority
api.adjust_priorities_for_items = adjust_priorities_for_items
api.apply_dynamic_adjustments = apply_dynamic_adjustments

return api
