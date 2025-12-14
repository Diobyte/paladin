-- Shield Charge - Valor Skill (Juggernaut/Channeled/Mobility)
-- Cooldown: 10s | Lucky Hit: 35%
-- Charge with your shield and push enemies Back, granting 10% Damage Reduction and dealing 90% damage while Channeling.
-- Physical Damage | Requires Shield

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_shield_charge_enabled")),
    targeting_mode = combo_box:new(4, get_hash("paladin_rotation_shield_charge_targeting_mode")),  -- Default: 4 = Closest Target
    min_cooldown = slider_float:new(0.0, 5.0, 0.3, get_hash("paladin_rotation_shield_charge_min_cd")),  -- Fast mobility
    min_range = slider_float:new(2.0, 15.0, 6.0, get_hash("paladin_rotation_shield_charge_min_range")),  -- Only charge from mid-range
    max_range = slider_float:new(5.0, 30.0, 15.0, get_hash("paladin_rotation_shield_charge_max_range")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_shield_charge_enemy_type")),
    use_for_engage_only = checkbox:new(true, get_hash("paladin_rotation_shield_charge_engage_only")),
}

local spell_id = spell_data.shield_charge.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Shield Charge") then
        menu_elements.main_boolean:render("Enable", "Valor Channeled - 10% DR + 90% damage (CD: 10s)")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, my_utility.targeting_mode_description)
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.min_range:render("Min Range", "Minimum distance to target before charging", 1)
            menu_elements.max_range:render("Max Range", "Maximum distance to target for charging", 1)
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_for_engage_only:render("Use for Engage Only", "Only use Shield Charge to engage targets at range")
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    if not target then return false end
    
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then return false end

    -- Validate target (Druid pattern - simple checks)
    if not target:is_enemy() then return false end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then return false end

    -- Enemy type filter check
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    if enemy_type_filter == 2 then
        if not target:is_boss() then return false end
    elseif enemy_type_filter == 1 then
        if not (target:is_elite() or target:is_champion() or target:is_boss()) then
            return false
        end
    end

    local player = get_local_player()
    if not player then return false end
    
    local player_pos = player:get_position()
    local target_pos = target:get_position()
    
    if not player_pos or not target_pos then return false end
    
    local dist = player_pos:dist_to(target_pos)
    local min_r = menu_elements.min_range:get()
    local max_r = menu_elements.max_range:get()
    
    -- Range check - must be between min and max range
    if dist < min_r or dist > max_r then return false end

    -- Check for wall collision
    if target_selector and target_selector.is_wall_collision then
        local is_wall_collision = target_selector.is_wall_collision(player_pos, target, 1.20)
        if is_wall_collision then return false end
    end

    -- Use prediction for moving targets
    local cast_pos = target_pos
    if prediction and prediction.get_future_unit_position then
        local predicted_pos = prediction.get_future_unit_position(target, 0.2)
        if predicted_pos then
            cast_pos = predicted_pos
        end
    end

    if cast_spell.position(spell_id, cast_pos, 0.0) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast
        local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
        console.print("Cast Shield Charge - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
        return true
    end

    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
