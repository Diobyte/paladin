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
    min_cooldown = slider_float:new(0.0, 1.0, 0.05, get_hash("paladin_rotation_holy_bolt_min_cd")),
    use_for_judgement = checkbox:new(false, get_hash("paladin_rotation_holy_bolt_judgement_mode")),
    resource_threshold = slider_int:new(0, 100, 30, get_hash("paladin_rotation_holy_bolt_resource_threshold")),  -- Only gen when Faith below 30%
    prediction_time = slider_float:new(0.1, 0.8, 0.25, get_hash("paladin_rotation_holy_bolt_prediction")),  -- Slightly faster prediction
}

local spell_id = spell_data.holy_bolt.spell_id
local next_time_allowed_cast = 0.0
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
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
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
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        return false, 0 
    end

    if not target then
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
                return false, 0  -- Faith is high enough, let spenders handle it
            end
        end
    end

    local is_target_enemy = false
    if target then
        local ok, res = pcall(function() return target:is_enemy() end)
        is_target_enemy = ok and res or false
    end

    if not is_target_enemy then
        return false, 0
    end
    
    -- Filter out dead, immune, and untargetable targets per API guidelines
    local is_dead = false
    local is_immune = false
    local is_untargetable = false
    local ok_dead, res_dead = pcall(function() return target:is_dead() end)
    local ok_immune, res_immune = pcall(function() return target:is_immune() end)
    local ok_untarget, res_untarget = pcall(function() return target:is_untargetable() end)
    is_dead = ok_dead and res_dead or false
    is_immune = ok_immune and res_immune or false
    is_untargetable = ok_untarget and res_untarget or false
    
    if is_dead or is_immune or is_untargetable then
        return false, 0
    end

    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    if not player_pos then
        return false, 0
    end
    
    local tpos = target:get_position()
    if not tpos then
        return false, 0
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    if cast_spell and type(cast_spell.target) == "function" then
        if cast_spell.target(target, spell_id, 0.0, false) then
            next_time_allowed_cast = now + cooldown
            return true, cooldown
        end
        dbg("cast failed")
    end

    if cast_spell and type(cast_spell.position) == "function" then
        local tpos = target:get_position()
        
        -- Use prediction for moving targets
        local prediction_time = menu_elements.prediction_time:get()
        if prediction and prediction.get_future_unit_position then
            local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
            if predicted_pos then
                tpos = predicted_pos
            end
        end

        if tpos and cast_spell.position(spell_id, tpos, 0.0) then
            next_time_allowed_cast = now + cooldown
            return true, cooldown
        end
        dbg("cast failed (position)")
    end

    if cast_spell and type(cast_spell.self) == "function" then
        if cast_spell.self(spell_id, 0.0) then
            next_time_allowed_cast = now + cooldown
            return true, cooldown
        end
        dbg("cast failed (self)")
    end

    dbg_api_once_per_sec("no cast api (targeted/position/self)")

    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
