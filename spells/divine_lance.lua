-- Divine Lance - Core Skill (Disciple/Mobility)
-- Faith Cost: 25 | Lucky Hit: 6%
-- Impale enemies with a heavenly lance, stabbing 2 times for 90% damage each.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_divine_lance_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_divine_lance_debug_mode")),
    targeting_mode = combo_box:new(4, get_hash("paladin_rotation_divine_lance_targeting_mode")),  -- Default: 4 = Closest Target
    min_cooldown = slider_float:new(0.0, 5.0, 0.15, get_hash("paladin_rotation_divine_lance_min_cd")),  -- Fast spender
    cast_range = slider_float:new(3.0, 10.0, 5.0, get_hash("paladin_rotation_divine_lance_cast_range")),  -- Melee impale range
    min_resource = slider_int:new(0, 100, 20, get_hash("paladin_rotation_divine_lance_min_resource")),  -- Only need some Faith
    prediction_time = slider_float:new(0.1, 0.8, 0.25, get_hash("paladin_rotation_divine_lance_prediction")),  -- Faster prediction
}

local spell_id = spell_data.divine_lance.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Divine Lance") then
        menu_elements.main_boolean:render("Enable", "Core Skill - Stab 2x for 90% each (Faith Cost: 25)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, my_utility.targeting_mode_description)
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.cast_range:render("Cast Range", "Range to cast impale", 1)
            menu_elements.min_resource:render("Min Resource %", "Only cast when Faith above this %")
            menu_elements.prediction_time:render("Prediction Time", "How far ahead to predict enemy position", 2)
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    local debug_enabled = menu_elements.debug_mode:get()
    
    if not target then
        if debug_enabled then console.print("[DIVINE LANCE DEBUG] No target provided") end
        return false, 0
    end
    
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then
        if debug_enabled then console.print("[DIVINE LANCE DEBUG] Spell not allowed") end
        return false, 0
    end

    -- Validate target (Druid pattern - simple checks)
    if not target:is_enemy() then
        if debug_enabled then console.print("[DIVINE LANCE DEBUG] Target is not an enemy") end
        return false, 0
    end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then
        if debug_enabled then console.print("[DIVINE LANCE DEBUG] Target is dead/immune/untargetable") end
        return false, 0
    end

    -- Resource check (Faith Cost: 25)
    local min_resource = menu_elements.min_resource:get()
    if min_resource > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) < min_resource then
            if debug_enabled then console.print("[DIVINE LANCE DEBUG] Insufficient Faith") end
            return false, 0
        end
    end

    -- Range check for Divine Lance (melee impale skill)
    local cast_range = menu_elements.cast_range:get()
    local in_range = my_utility.is_in_range(target, cast_range)
    
    if not in_range then
        if debug_enabled then console.print("[DIVINE LANCE DEBUG] Target out of range") end
        return false, 0
    end

    local cooldown = menu_elements.min_cooldown:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end

    -- Divine Lance is primarily a melee/short-range impale skill
    if cast_spell.target(target, spell_id, 0.0, false) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then
            local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
            console.print("[DIVINE LANCE DEBUG] Cast successful - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
        end
        return true, cooldown
    end

    -- Fallback to position cast with prediction (for Divine Javelin upgrade - ranged throw)
    local cast_pos = target:get_position()
    if cast_pos then
        local prediction_time = menu_elements.prediction_time:get()
        if prediction and prediction.get_future_unit_position then
            local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
            if predicted_pos then
                cast_pos = predicted_pos
            end
        end

        if cast_spell.position(spell_id, cast_pos, 0.0) then
            local current_time = get_time_since_inject()
            next_time_allowed_cast = current_time + cooldown
            if debug_enabled then
                local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
                console.print("[DIVINE LANCE DEBUG] Cast successful (position) - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
            end
            return true, cooldown
        end
    end

    if debug_enabled then console.print("[DIVINE LANCE DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
