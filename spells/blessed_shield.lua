-- Blessed Shield - Core Skill (Judicator)
-- Faith Cost: 28 | Lucky Hit: 30%
-- Bless and hurl your shield with Holy energy, dealing 216% damage that ricochets up to 3 times.
-- Holy Damage | Requires Shield
-- Note: Extended melee skill (5.5-6.0 range), works on single target or grouped enemies

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_blessed_shield_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_blessed_shield_debug_mode")),
    targeting_mode = combo_box:new(4, get_hash("paladin_rotation_blessed_shield_targeting_mode")),  -- Default: 4 = Closest Target (prevents "freaking out")
    min_cooldown = slider_float:new(0.0, 1.0, 0.15, get_hash("paladin_rotation_blessed_shield_min_cd")),  -- Fast for shield builds
    cast_range = slider_float:new(3.0, 10.0, 6.0, get_hash("paladin_rotation_blessed_shield_cast_range")),
    min_resource = slider_int:new(0, 100, 25, get_hash("paladin_rotation_blessed_shield_min_resource")),  -- Lower threshold for more spam
    use_on_single_target = checkbox:new(true, get_hash("paladin_rotation_blessed_shield_single_target")),
    prefer_grouped_enemies = checkbox:new(true, get_hash("paladin_rotation_blessed_shield_prefer_grouped")),
    min_enemies_for_aoe = slider_int:new(2, 10, 2, get_hash("paladin_rotation_blessed_shield_min_enemies")),
    ricochet_grouping = slider_float:new(3.0, 10.0, 6.0, get_hash("paladin_rotation_blessed_shield_ricochet_grouping")),
}

local spell_id = spell_data.blessed_shield.spell_id
local next_time_allowed_cast = 0.0
-- Movement is now handled by my_utility.move_to_target() centralized system

local function menu()
    if menu_elements.tree_tab:push("Blessed Shield") then
        menu_elements.main_boolean:render("Enable", "Extended melee skill (5.5-6.0 range), ricochets 3x (Faith Cost: 28)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, my_utility.targeting_mode_description)
            menu_elements.min_cooldown:render("Min Cooldown", "Minimum time between casts", 2)
            menu_elements.cast_range:render("Cast Range", "Must be within this range to cast (extended melee)", 1)
            menu_elements.min_resource:render("Min Resource %", "Only cast when Faith above this %")
            menu_elements.use_on_single_target:render("Use on Single Target", "Cast even when only one enemy is present")
            menu_elements.prefer_grouped_enemies:render("Prefer Grouped Enemies", "Prioritize casting when enemies are grouped for ricochet")
            if menu_elements.prefer_grouped_enemies:get() then
                menu_elements.min_enemies_for_aoe:render("Min Enemies for AoE", "Prefer groups of this size or larger")
                menu_elements.ricochet_grouping:render("Ricochet Grouping", "Enemies within this range count for ricochet", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    local debug_enabled = menu_elements.debug_mode:get()
    
    -- Step 1: Basic checks that don't depend on cooldowns/resources
    if not target then
        if debug_enabled then console.print("[BLESSED SHIELD DEBUG] No target provided") end
        return false, 0
    end
    
    local menu_boolean = menu_elements.main_boolean:get()
    if not menu_boolean then
        return false, 0
    end

    -- Step 2: Validate target (Druid pattern - simple checks)
    if not target:is_enemy() then
        if debug_enabled then console.print("[BLESSED SHIELD DEBUG] Target is not an enemy") end
        return false, 0
    end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then
        if debug_enabled then console.print("[BLESSED SHIELD DEBUG] Target is dead/immune/untargetable") end
        return false, 0
    end

    local player = get_local_player()
    if not player then return false, 0 end
    
    -- Step 3: Range check FIRST - move toward target if out of range
    -- This happens BEFORE cooldown/resource checks (Spiritborn pattern)
    local cast_range = menu_elements.cast_range:get()
    local in_range = my_utility.is_in_range(target, cast_range)
    
    if not in_range then
        -- CENTRALIZED MOVEMENT: Use my_utility.move_to_target()
        -- This is called regardless of cooldown state - we want to close distance
        my_utility.move_to_target(target:get_position(), target:get_id())
        if debug_enabled then console.print("[BLESSED SHIELD DEBUG] Moving toward target (out of range)") end
        return false, 0
    end
    
    -- Step 4: Now check if spell is actually ready to cast (cooldowns, resources, orbwalker mode)
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id, debug_enabled)
    
    if not is_logic_allowed then
        if debug_enabled then console.print("[BLESSED SHIELD DEBUG] Spell not allowed (cooldown/resource/mode)") end
        return false, 0
    end
    
    -- Step 5: Resource check (Faith Cost: 28 - expensive spender)
    local min_resource = menu_elements.min_resource:get()
    if min_resource > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) < min_resource then
            if debug_enabled then console.print("[BLESSED SHIELD DEBUG] Insufficient Faith") end
            return false, 0
        end
    end
    
    -- Step 6: Check if we should cast based on single target / grouped enemy preferences
    local should_cast = false
    local use_single = menu_elements.use_on_single_target:get()
    local prefer_grouped = menu_elements.prefer_grouped_enemies:get()
    
    if prefer_grouped then
        -- Count enemies near target for ricochet value (shield bounces 3x)
        local ricochet_range = menu_elements.ricochet_grouping:get()
        local min_enemies = menu_elements.min_enemies_for_aoe:get()
        local all_units_count = my_utility.enemy_count_in_radius(ricochet_range)

        if all_units_count >= min_enemies then
            should_cast = true  -- Good ricochet opportunity
        elseif use_single and all_units_count >= 1 then
            should_cast = true  -- Single target fallback allowed
        end
    else
        -- No preference for grouped - just check single target setting
        should_cast = use_single
    end
    
    if not should_cast then
        if debug_enabled then console.print("[BLESSED SHIELD DEBUG] Conditions not met for cast") end
        return false, 0
    end

    local cooldown = menu_elements.min_cooldown:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end

    if cast_spell.target(target, spell_id, 0.0, false) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then
            local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
            console.print("[BLESSED SHIELD DEBUG] Cast successful - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
        end
        return true, cooldown
    end

    if debug_enabled then console.print("[BLESSED SHIELD DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
