-- Spear of the Heavens - Justice Skill (Judicator)
-- Cooldown: 14s | Lucky Hit: 33%
-- Rain down 4 heavenly spears from the sky, dealing 160% damage and Knocking Down enemies for 1.5s.
-- After 1.5s, the spears burst for 120% damage.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_spear_of_the_heavens_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_spear_of_the_heavens_debug_mode")),
    min_cooldown = slider_float:new(0.0, 10.0, 0.15, get_hash("paladin_rotation_spear_of_the_heavens_min_cd")),  -- Fast burst
    cast_range = slider_float:new(5.0, 25.0, 15.0, get_hash("paladin_rotation_spear_of_the_heavens_cast_range")),  -- Max range to cast
    targeting_mode = combo_box:new(0, get_hash("paladin_rotation_spear_of_the_heavens_targeting_mode")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_spear_of_the_heavens_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_spear_of_the_heavens_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_spear_of_the_heavens_min_weight")),
    prediction_time = slider_float:new(0.1, 0.8, 0.25, get_hash("paladin_rotation_spear_of_the_heavens_prediction")),  -- Slightly faster
}

local spell_id = spell_data.spear_of_the_heavens.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Spear of the Heavens") then
        menu_elements.main_boolean:render("Enable", "Justice - 4 spears for 160% + 120% burst (CD: 14s)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.cast_range:render("Cast Range", "Maximum distance to target for casting", 1)
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
        if debug_enabled then console.print("[SPEAR DEBUG] No target provided") end
        return false, 0
    end
    
    local menu_boolean = menu_elements.main_boolean:get()
    if not menu_boolean then
        return false, 0
    end

    -- Validate target (Druid pattern - simple checks)
    if not target:is_enemy() then
        if debug_enabled then console.print("[SPEAR DEBUG] Target is not an enemy") end
        return false, 0
    end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then
        if debug_enabled then console.print("[SPEAR DEBUG] Target is dead/immune/untargetable") end
        return false, 0
    end

    -- Check readiness BEFORE movement to avoid walking while on cooldown/resource/mode gate
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id, debug_enabled)
    if not is_logic_allowed then
        if debug_enabled then console.print("[SPEAR DEBUG] Spell not allowed (cooldown/mode)") end
        return false, 0
    end

    -- Range check AFTER gating - Spear is ranged so we move if out of range
    local cast_range = menu_elements.cast_range:get()
    if not my_utility.is_in_range(target, cast_range) then
        -- Move toward target if out of range
        my_utility.move_to_target(target:get_position(), target:get_id())
        if debug_enabled then console.print("[SPEAR DEBUG] Moving toward target - out of range") end
        return false, 0
    end

    -- Enemy type filter check
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    if enemy_type_filter == 2 then
        if not target:is_boss() then
            if debug_enabled then console.print("[SPEAR DEBUG] Target is not a boss") end
            return false, 0
        end
    elseif enemy_type_filter == 1 then
        if not (target:is_elite() or target:is_champion() or target:is_boss()) then
            if debug_enabled then console.print("[SPEAR DEBUG] Target is not elite+") end
            return false, 0
        end
    end

    local pos = target:get_position()
    if not pos then return false, 0 end

    -- Use prediction for moving targets, but keep the point inside cast range so we do not whiff
    local prediction_time = menu_elements.prediction_time:get()
    if prediction and prediction.get_future_unit_position then
        local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
        if predicted_pos then
            pos = predicted_pos
        end
    end

    -- If the predicted point ends outside cast range, walk closer instead of tossing the cast
    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    if player_pos and pos and player_pos:dist_to(pos) > cast_range then
        my_utility.move_to_target(pos, target:get_id())
        if debug_enabled then console.print("[SPEAR DEBUG] Predicted point out of range - moving") end
        return false, 0
    end

    -- Optional pack-density gate ("minimum weight" is treated as enemy count in 6m)
    local use_minimum_weight = menu_elements.use_minimum_weight:get()
    local minimum_weight = math.ceil(menu_elements.minimum_weight:get())
    if use_minimum_weight and minimum_weight > 0 and enemy_type_filter == 0 then
        local nearby = my_utility.enemy_count_in_radius(6.0, pos)
        if nearby < minimum_weight then
            if debug_enabled then console.print("[SPEAR DEBUG] Not enough enemies at impact: " .. nearby .. " < " .. minimum_weight) end
            return false, 0
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
            console.print("[SPEAR DEBUG] Cast successful - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
        end
        return true, cooldown
    end

    if debug_enabled then console.print("[SPEAR DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
