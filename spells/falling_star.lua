-- Falling Star - Valor Skill (Disciple/Mobility)
-- Cooldown: 12s | Lucky Hit: 24%
-- Soar into the air with angelic wings and dive onto the battlefield, dealing 80% damage on takeoff and 240% damage on landing.
-- Holy Damage
-- META CRITICAL: "Use Falling Star OR Condemn every few seconds to stay in Arbiter form"
-- ARBITER TRIGGER via Disciple Oath - essential for Hammerdin builds!

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_falling_star_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_falling_star_debug_mode")),
    min_cooldown = slider_float:new(0.1, 10.0, 0.15, get_hash("paladin_rotation_falling_star_min_cd")),  -- META: ARBITER TRIGGER - cast ASAP
    min_range = slider_float:new(0.0, 10.0, 0.0, get_hash("paladin_rotation_falling_star_min_range")),  -- 0 = always leap
    max_range = slider_float:new(5.0, 25.0, 15.0, get_hash("paladin_rotation_falling_star_max_range")),  -- Max leap range
    targeting_mode = combo_box:new(0, get_hash("paladin_rotation_falling_star_targeting_mode")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_falling_star_enemy_type")),  -- 0 = All (Arbiter form priority)
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_falling_star_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_falling_star_min_weight")),
    prediction_time = slider_float:new(0.1, 1.0, 0.25, get_hash("paladin_rotation_falling_star_prediction")),  -- Slightly reduced for faster landing
}

local spell_id = spell_data.falling_star.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Falling Star") then
        menu_elements.main_boolean:render("Enable", "ARBITER TRIGGER - 320% damage + mobility (CD: 12s)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.min_cooldown:render("Min Cooldown", "Lower = more Arbiter uptime (CRITICAL)", 2)
            menu_elements.min_range:render("Min Range", "Minimum distance to target before leaping (0 = always)", 1)
            menu_elements.max_range:render("Max Range", "Maximum distance to target for leaping", 1)
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, "How to select target")
            menu_elements.prediction_time:render("Prediction Time", "How far ahead to predict enemy position", 2)
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    local debug_enabled = menu_elements.debug_mode:get()
    
    if not target then
        if debug_enabled then console.print("[FALLING STAR DEBUG] No target provided") end
        return false, 0
    end
    
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then
        if debug_enabled then console.print("[FALLING STAR DEBUG] Spell not allowed") end
        return false, 0
    end

    -- Validate target (Druid pattern - simple checks)
    if not target:is_enemy() then
        if debug_enabled then console.print("[FALLING STAR DEBUG] Target is not an enemy") end
        return false, 0
    end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then
        if debug_enabled then console.print("[FALLING STAR DEBUG] Target is dead/immune/untargetable") end
        return false, 0
    end

    -- Check range (min and max)
    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    local target_pos = target:get_position()
    
    if player_pos and target_pos then
        local dist = player_pos:dist_to(target_pos)
        
        -- Min range check
        local min_range = menu_elements.min_range:get()
        if min_range > 0 and dist < min_range then
            if debug_enabled then console.print("[FALLING STAR DEBUG] Target too close: " .. string.format("%.1f", dist)) end
            return false, 0  -- Too close to leap (but 0 = always leap for Arbiter trigger)
        end
        
        -- Max range check
        local max_range = menu_elements.max_range:get()
        if dist > max_range then
            if debug_enabled then console.print("[FALLING STAR DEBUG] Target too far: " .. string.format("%.1f", dist)) end
            return false, 0  -- Too far to leap
        end
    end

    -- Enemy type filter check
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    if enemy_type_filter == 2 then
        -- Boss only
        if not target:is_boss() then
            if debug_enabled then console.print("[FALLING STAR DEBUG] Target is not a boss") end
            return false, 0
        end
    elseif enemy_type_filter == 1 then
        -- Elite/Champion/Boss
        if not (target:is_elite() or target:is_champion() or target:is_boss()) then
            if debug_enabled then console.print("[FALLING STAR DEBUG] Target is not elite+") end
            return false, 0
        end
    end

    local pos = target:get_position()
    if not pos then
        if debug_enabled then console.print("[FALLING STAR DEBUG] Cannot get target position") end
        return false, 0
    end
    
    -- Use prediction for AoE placement
    local prediction_time = menu_elements.prediction_time:get()
    if prediction and prediction.get_future_unit_position then
        local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
        if predicted_pos then
            pos = predicted_pos
        end
    end

    local cooldown = menu_elements.min_cooldown:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end

    if cast_spell.position(spell_id, pos, 0.0) then
        local current_time = my_utility.safe_get_time()
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then
            local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
            console.print("[FALLING STAR DEBUG] Cast successful - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
        end
        return true, cooldown
    end

    if debug_enabled then console.print("[FALLING STAR DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
