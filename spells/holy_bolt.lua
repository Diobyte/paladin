local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local menu_module = require("menu")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_holy_bolt_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.05, get_hash("paladin_rotation_holy_bolt_min_cd")),
}

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
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(best_target, area_analysis)
    if not menu_elements.main_boolean:get() then return false end

    local now = my_utility.safe_get_time()
    if now < next_time_allowed_cast then return false end

    local spell_id = spell_data.holy_bolt.spell_id
    if not my_utility.is_spell_ready(spell_id) then
        dbg("not ready")
        return false
    end

    local target = best_target
    if not target then
        dbg("no target")
        return false
    end

    local is_target_enemy = false
    if target then
        local ok, res = pcall(function() return target:is_enemy() end)
        is_target_enemy = ok and res or false
    end

    if not is_target_enemy then
        dbg("target not enemy")
        return false
    end

    local player = get_local_player and get_local_player() or nil
    local player_pos = player and player.get_position and player:get_position() or nil
    if player_pos then
        local tpos = target.get_position and target:get_position() or nil
        if not tpos then
            dbg("target has no position")
            return false
        end
    end

    if cast_spell and type(cast_spell.targeted) == "function" then
        if cast_spell.targeted(spell_id, target, 0.0) then
            next_time_allowed_cast = now + menu_elements.min_cooldown:get()
            return true
        end
        dbg("cast failed")
    end

    if cast_spell and type(cast_spell.position) == "function" then
        local tpos = target.get_position and target:get_position() or nil
        
        -- Prediction
        if prediction and prediction.get_future_unit_position then
            local predicted_pos = prediction.get_future_unit_position(target, 0.3)
            if predicted_pos then
                tpos = predicted_pos
            end
        end

        if tpos and cast_spell.position(spell_id, tpos, 0.0) then
            next_time_allowed_cast = now + menu_elements.min_cooldown:get()
            return true
        end
        dbg("cast failed (position)")
    end

    if cast_spell and type(cast_spell.self) == "function" then
        if cast_spell.self(spell_id, 0.0) then
            next_time_allowed_cast = now + menu_elements.min_cooldown:get()
            return true
        end
        dbg("cast failed (self)")
    end

    dbg_api_once_per_sec("no cast api (targeted/position/self)")

    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
