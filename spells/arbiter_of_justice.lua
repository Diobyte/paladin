-- Arbiter of Justice - Ultimate Skill (Disciple/Mobility)
-- Cooldown: 120s | Lucky Hit: 16%
-- Ascend to the heavens and crash upon the battlefield as an Arbiter for 20 seconds, dealing 600% damage upon landing.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_arbiter_enabled")),
    min_cooldown = slider_float:new(0.2, 10.0, 0.5, get_hash("paladin_rotation_arbiter_min_cd")),  -- React fast when ult is up
    max_range = slider_float:new(5.0, 30.0, 20.0, get_hash("paladin_rotation_arbiter_max_range")),  -- Max leap range
    targeting_mode = combo_box:new(0, get_hash("paladin_rotation_arbiter_targeting_mode")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_arbiter_enemy_type")),  -- 0 = use on any target for Arbiter form
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_arbiter_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_arbiter_min_weight")),
    prediction_time = slider_float:new(0.1, 0.8, 0.25, get_hash("paladin_rotation_arbiter_prediction")),  -- Faster prediction
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_arbiter_debug_mode")),
}

local spell_id = spell_data.arbiter_of_justice.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Arbiter of Justice") then
        menu_elements.main_boolean:render("Enable", "Ultimate - 600% landing, Arbiter form 20s (CD: 120s)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.max_range:render("Max Range", "Maximum distance to target for leaping", 1)
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, "How to select target")
            menu_elements.prediction_time:render("Prediction Time", "How far ahead to predict enemy position", 2)
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    local debug_enabled = menu_elements.debug_mode:get()
    
    if not target then 
        if debug_enabled then console.print("[ARBITER DEBUG] No target") end
        return false, 0 
    end
    
    local menu_boolean = menu_elements.main_boolean:get()
    if not menu_boolean then
        return false, 0
    end

    -- Validate target (Druid pattern - simple checks)
    if not target:is_enemy() then 
        if debug_enabled then console.print("[ARBITER DEBUG] Target not enemy") end
        return false, 0 
    end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then 
        if debug_enabled then console.print("[ARBITER DEBUG] Target dead/immune/untargetable") end
        return false, 0 
    end

    -- Max range check for leap - move toward target if out of range
    local max_range = menu_elements.max_range:get()
    if not my_utility.is_in_range(target, max_range) then
        my_utility.move_to_target(target:get_position(), target:get_id())
        if debug_enabled then console.print("[ARBITER DEBUG] Moving toward target - out of leap range") end
        return false, 0
    end

    -- NOW check if spell is ready (cooldown, orbwalker mode, etc.)
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id, debug_enabled)
    if not is_logic_allowed then 
        if debug_enabled then console.print("[ARBITER DEBUG] Spell not allowed (cooldown/mode)") end
        return false, 0 
    end

    -- Enemy type filter check
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    if enemy_type_filter == 2 then
        if not target:is_boss() then 
            if debug_enabled then console.print("[ARBITER DEBUG] Target not boss (filter=Boss)") end
            return false, 0 
        end
    elseif enemy_type_filter == 1 then
        if not (target:is_elite() or target:is_champion() or target:is_boss()) then
            if debug_enabled then console.print("[ARBITER DEBUG] Target not elite+ (filter=Elite+)") end
            return false, 0
        end
    end

    local cooldown = menu_elements.min_cooldown:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end

    -- Try direct target cast first
    if cast_spell.target(target, spell_id, 0.0, false) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + cooldown
        local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
        console.print("Cast Arbiter of Justice - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
        return true, cooldown
    end

    -- Fallback to position cast with prediction
    local pos = target:get_position()
    if pos then
        local prediction_time = menu_elements.prediction_time:get()
        if prediction and prediction.get_future_unit_position then
            local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
            if predicted_pos then
                pos = predicted_pos
            end
        end

        if cast_spell.position(spell_id, pos, 0.0) then
            local current_time = get_time_since_inject()
            next_time_allowed_cast = current_time + cooldown
            local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
            console.print("Cast Arbiter of Justice (position) - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
            return true, cooldown
        end
    end

    if debug_enabled then console.print("[ARBITER DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
