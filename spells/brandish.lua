-- Brandish - Basic Skill (Disciple)
-- Generate Faith: 14 | Lucky Hit: 20%
-- Brandish the Light, unleashing an arc that deals 75% damage.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_brandish_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_brandish_debug_mode")),
    targeting_mode = combo_box:new(4, get_hash("paladin_rotation_brandish_targeting_mode")),  -- Default: 4 = Closest Target
    min_cooldown = slider_float:new(0.0, 5.0, 0.08, get_hash("paladin_rotation_brandish_min_cd")),  -- Fast backup generator
    resource_threshold = slider_int:new(0, 100, 25, get_hash("paladin_rotation_brandish_resource_threshold")),  -- Only when Faith very low (backup)
}

local spell_id = spell_data.brandish.spell_id
local next_time_allowed_cast = 0.0
-- Movement is now handled by my_utility.move_to_target() centralized system

local function menu()
    if menu_elements.tree_tab:push("Brandish") then
        menu_elements.main_boolean:render("Enable", "Basic Generator - Arc for 75% (Generate 14 Faith)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, my_utility.targeting_mode_description)
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.resource_threshold:render("Resource Threshold %", "Only use when Faith BELOW this % (backup generator)")
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    local debug_enabled = menu_elements.debug_mode:get()
    
    if not target then
        if debug_enabled then console.print("[BRANDISH DEBUG] No target provided") end
        return false, 0
    end
    
    local menu_boolean = menu_elements.main_boolean:get()
    if not menu_boolean then
        return false, 0
    end

    -- Validate target (Druid pattern - simple checks)
    if not target:is_enemy() then
        if debug_enabled then console.print("[BRANDISH DEBUG] Target is not an enemy") end
        return false, 0
    end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then
        if debug_enabled then console.print("[BRANDISH DEBUG] Target is dead/immune/untargetable") end
        return false, 0
    end

    -- Check readiness BEFORE movement to avoid walking while on cooldown/resource gated
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id, debug_enabled)
    if not is_logic_allowed then
        if debug_enabled then console.print("[BRANDISH DEBUG] Spell not allowed (cooldown/mode)") end
        return false, 0
    end

    -- Range check AFTER gating (Brandish has slightly longer arc range)
    local cast_range = 4.0
    local in_range = my_utility.is_in_range(target, cast_range)
    
    -- CENTRALIZED MOVEMENT: If out of range, move toward target
    if not in_range then
        my_utility.move_to_target(target:get_position(), target:get_id())
        if debug_enabled then console.print("[BRANDISH DEBUG] Moving toward target - out of range") end
        return false, 0  -- Don't cast, just move
    end

    -- GENERATOR LOGIC: Only cast when Faith is LOW (backup generator)
    local threshold = menu_elements.resource_threshold:get()
    local burn_override = _G.PaladinRotation and _G.PaladinRotation.boss_burn_mode and (target:is_elite() or target:is_champion() or target:is_boss())
    if (threshold > 0) and (not burn_override) then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) >= threshold then
            if debug_enabled then console.print("[BRANDISH DEBUG] Faith too high") end
            return false, 0  -- Faith is high enough, let spenders handle it
        end
    end

    local cooldown = menu_elements.min_cooldown:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end

    if cast_spell.target(target, spell_id, 0.0, false) then
        local current_time = my_utility.safe_get_time()
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then
            local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
            console.print("[BRANDISH DEBUG] Cast successful - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
        end
        return true, cooldown
    end

    if debug_enabled then console.print("[BRANDISH DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
