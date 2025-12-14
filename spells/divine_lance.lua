-- Divine Lance - Core Skill (Disciple/Mobility)
-- Faith Cost: 25 | Lucky Hit: 6%
-- Impale enemies with a heavenly lance, stabbing 2 times for 90% damage each.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_divine_lance_enabled")),
    min_cooldown = slider_float:new(0.0, 5.0, 0.15, get_hash("paladin_rotation_divine_lance_min_cd")),  -- Fast spender
    cast_range = slider_float:new(3.0, 10.0, 5.0, get_hash("paladin_rotation_divine_lance_cast_range")),  -- Melee impale range
    min_resource = slider_int:new(0, 100, 20, get_hash("paladin_rotation_divine_lance_min_resource")),  -- Only need some Faith
    prediction_time = slider_float:new(0.1, 0.8, 0.25, get_hash("paladin_rotation_divine_lance_prediction")),  -- Faster prediction
}

local spell_id = spell_data.divine_lance.spell_id
local next_time_allowed_cast = 0.0
local next_time_allowed_move = 0.0
local move_delay = 0.25  -- Delay between movement commands (like druid script)

local function menu()
    if menu_elements.tree_tab:push("Divine Lance") then
        menu_elements.main_boolean:render("Enable", "Core Skill - Stab 2x for 90% each (Faith Cost: 25)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.cast_range:render("Cast Range", "Range to cast impale", 1)
            menu_elements.min_resource:render("Min Resource %", "Only cast when Faith above this %")
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
    
    local is_target_enemy = false
    local ok, res = pcall(function() return target:is_enemy() end)
    is_target_enemy = ok and res or false
    
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

    -- Resource check (Faith Cost: 25)
    local min_resource = menu_elements.min_resource:get()
    if min_resource > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) < min_resource then
            return false, 0
        end
    end

    local cast_pos = target:get_position()
    if not cast_pos then 
        return false, 0 
    end
    
    -- Range check for Divine Lance (melee impale skill)
    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    if player_pos then
        local cast_range = menu_elements.cast_range:get()
        local dist_sqr = player_pos:squared_dist_to_ignore_z(cast_pos)
        if dist_sqr > (cast_range * cast_range) then
            -- Out of range - move toward target (like druid script)
            local current_time = my_utility.safe_get_time()
            if current_time >= next_time_allowed_move then
                if pathfinder and pathfinder.force_move_raw then
                    pathfinder.force_move_raw(cast_pos)
                    next_time_allowed_move = current_time + move_delay
                end
            end
            return false, 0
        end
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Divine Lance is primarily a melee/short-range impale skill
    -- "Impale enemies with a heavenly lance, stabbing 2 times for 90% damage each"
    -- Try direct target cast first (preferred for melee impale)
    if cast_spell and type(cast_spell.target) == "function" then
        if cast_spell.target(target, spell_id, 0.0, false) then
            next_time_allowed_cast = now + cooldown
            return true, cooldown
        end
    end

    -- Fallback to position cast with prediction (for Divine Javelin upgrade - ranged throw)
    cast_pos = target:get_position()
    local prediction_time = menu_elements.prediction_time:get()
    if prediction and prediction.get_future_unit_position then
        local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
        if predicted_pos then
            cast_pos = predicted_pos
        end
    end

    if cast_spell and type(cast_spell.position) == "function" then
        if cast_spell.position(spell_id, cast_pos, 0.0) then
            next_time_allowed_cast = now + cooldown
            return true, cooldown
        end
    end

    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
