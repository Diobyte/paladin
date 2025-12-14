-- Holy Bolt - Basic Skill (Judicator)
-- Generate Faith: 16 | Lucky Hit: 44%
-- Throw a Holy hammer, dealing 90% damage.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local menu_module = require("menu")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_holy_bolt_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_holy_bolt_debug_mode")),
    targeting_mode = combo_box:new(0, get_hash("paladin_rotation_holy_bolt_targeting_mode")),  -- Default: 0 = Ranged Target
    min_cooldown = slider_float:new(0.0, 1.0, 0.05, get_hash("paladin_rotation_holy_bolt_min_cd")),
    cast_range = slider_float:new(5.0, 20.0, 12.0, get_hash("paladin_rotation_holy_bolt_cast_range")),  -- Ranged projectile
    use_for_judgement = checkbox:new(false, get_hash("paladin_rotation_holy_bolt_judgement_mode")),
    resource_threshold = slider_int:new(0, 100, 30, get_hash("paladin_rotation_holy_bolt_resource_threshold")),  -- Only gen when Faith below 30%
    prediction_time = slider_float:new(0.1, 0.8, 0.25, get_hash("paladin_rotation_holy_bolt_prediction")),  -- Slightly faster prediction
}

local spell_id = spell_data.holy_bolt.spell_id
local next_time_allowed_cast = 0.0
-- Movement is now handled by my_utility.move_to_target() centralized system
local last_api_debug_time = 0.0

local function dbg(msg)
    local enabled = false
    if menu_module and menu_module.menu_elements and menu_module.menu_elements.enable_debug then
        enabled = menu_module.menu_elements.enable_debug:get()
    end
    if enabled and console and type(console.print) == "function" then
        console.print("[Paladin_Rotation][Holy Bolt] " .. msg)
    end
end

local function dbg_api_once_per_sec(msg)
    local now = my_utility.safe_get_time()
    if now - last_api_debug_time >= 1.0 then
        last_api_debug_time = now
        dbg(msg)
    end
end

local function menu()
    if menu_elements.tree_tab:push("Holy Bolt") then
        menu_elements.main_boolean:render("Enable", "Basic Generator - Throw hammer for 90% (Generate 16 Faith)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, my_utility.targeting_mode_description)
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.cast_range:render("Cast Range", "Maximum distance to target for casting", 1)
            menu_elements.use_for_judgement:render("Judgement Build (Captain America)", "Always use to apply Judgement before Blessed Shield (ignore resource threshold)")
            if not menu_elements.use_for_judgement:get() then
                menu_elements.resource_threshold:render("Resource Threshold %", "Only use when Faith BELOW this % (set 0 for always)")
            end
            menu_elements.prediction_time:render("Prediction Time", "How far ahead to predict enemy position", 2)
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    local debug_enabled = menu_elements.debug_mode:get()
    
    if not target then
        if debug_enabled then console.print("[HOLY BOLT DEBUG] No target provided") end
        return false, 0
    end
    
    local menu_boolean = menu_elements.main_boolean:get()
    if not menu_boolean then
        return false, 0
    end

    -- Validate target (Druid pattern - simple checks)
    if not target:is_enemy() then
        if debug_enabled then console.print("[HOLY BOLT DEBUG] Target is not an enemy") end
        return false, 0
    end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then
        if debug_enabled then console.print("[HOLY BOLT DEBUG] Target is dead/immune/untargetable") end
        return false, 0
    end

    local player = get_local_player()
    if not player then return false, 0 end
    
    -- Range check FIRST for ranged projectile
    local cast_range = menu_elements.cast_range:get()
    if not my_utility.is_in_range(target, cast_range) then
        -- CENTRALIZED MOVEMENT: Move toward target
        my_utility.move_to_target(target:get_position(), target:get_id())
        if debug_enabled then console.print("[HOLY BOLT DEBUG] Moving toward target - out of range") end
        return false, 0  -- Don't cast, just move
    end

    -- NOW check if spell is ready (cooldown, orbwalker mode, etc.)
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id, debug_enabled)
    if not is_logic_allowed then
        if debug_enabled then console.print("[HOLY BOLT DEBUG] Spell not allowed (cooldown/mode)") end
        return false, 0
    end

    -- JUDGEMENT BUILD MODE (Captain America): Always cast to apply Judgement
    -- GENERATOR MODE: Only cast when Faith is LOW
    local judgement_mode = menu_elements.use_for_judgement:get()
    if not judgement_mode then
        local threshold = menu_elements.resource_threshold:get()
        if threshold > 0 then
            local resource_pct = my_utility.get_resource_pct()
            if resource_pct and (resource_pct * 100) >= threshold then
                if debug_enabled then console.print("[HOLY BOLT DEBUG] Faith too high") end
                return false, 0  -- Faith is high enough, let spenders handle it
            end
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
            console.print("[HOLY BOLT DEBUG] Cast successful - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
        end
        return true, cooldown
    end

    -- Fallback: Try position-based cast with prediction
    local tpos = target:get_position()
    if tpos then
        local prediction_time = menu_elements.prediction_time:get()
        if prediction and prediction.get_future_unit_position then
            local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
            if predicted_pos then
                tpos = predicted_pos
            end
        end

        if cast_spell.position(spell_id, tpos, 0.0) then
            local current_time = my_utility.safe_get_time()
            next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast
            if debug_enabled then
                local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
                console.print("[HOLY BOLT DEBUG] Cast successful (position) - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
            end
            return true
        end
    end

    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
