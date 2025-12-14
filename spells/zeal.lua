-- Zeal - Core Skill (Zealot)
-- Faith Cost: 20 | Lucky Hit: 3%
-- Strike enemies with blinding speed, dealing 80% damage followed by 3 additional strikes dealing 20% damage each.
-- Physical Damage
-- META NOTE: With Red Sermon unique, Zeal costs LIFE instead of Faith!

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_zeal_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_zeal_debug_mode")),
    targeting_mode = combo_box:new(4, get_hash("paladin_rotation_zeal_targeting_mode")),  -- Default: 4 = Closest Target (fixes targeting enemies in back)
    min_cooldown = slider_float:new(0.0, 1.0, 0.05, get_hash("paladin_rotation_zeal_min_cd")),
    min_resource = slider_int:new(0, 100, 15, get_hash("paladin_rotation_zeal_min_resource")),  -- Low threshold - spam if possible
    min_enemies = slider_int:new(1, 10, 1, get_hash("paladin_rotation_zeal_min_enemies")),
    use_life_mode = checkbox:new(false, get_hash("paladin_rotation_zeal_life_mode")),
}

local spell_id = spell_data.zeal.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Zeal") then
        menu_elements.main_boolean:render("Enable", "Core Skill - Fast 360 melee combo (Cost: 20 Faith or Life)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, my_utility.targeting_mode_description)
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.use_life_mode:render("Red Sermon Mode", "Using Red Sermon unique (costs Life instead of Faith)")
            if not menu_elements.use_life_mode:get() then
                menu_elements.min_resource:render("Min Faith %", "Only cast when Faith above this %")
            end
            menu_elements.min_enemies:render("Min Enemies", "Minimum enemies in melee range")
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    local debug_enabled = menu_elements.debug_mode:get()
    
    if not target then
        if debug_enabled then console.print("[ZEAL DEBUG] No target provided") end
        return false, 0
    end
    
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then
        if debug_enabled then console.print("[ZEAL DEBUG] Spell not allowed (disabled or on cooldown)") end
        return false, 0
    end

    -- Validate target (Druid pattern - simple checks)
    if not target:is_enemy() then
        if debug_enabled then console.print("[ZEAL DEBUG] Target is not an enemy") end
        return false, 0
    end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then
        if debug_enabled then console.print("[ZEAL DEBUG] Target is dead/immune/untargetable") end
        return false, 0
    end

    local player = get_local_player()
    if not player then return false, 0 end
    
    -- Resource check depends on build mode
    local use_life_mode = menu_elements.use_life_mode:get()
    
    if not use_life_mode then
        -- Standard Faith cost mode
        local current_resource = player:get_primary_resource_current()
        local max_resource = player:get_primary_resource_max()
        if max_resource > 0 then
            local resource_pct = (current_resource / max_resource) * 100
            local min_resource = menu_elements.min_resource:get()
            
            -- Must have enough Faith to cast (it's a spender)
            if resource_pct < min_resource then
                if debug_enabled then console.print("[ZEAL DEBUG] Insufficient Faith: " .. string.format("%.1f", resource_pct) .. "% < " .. min_resource .. "%") end
                return false, 0
            end
        end
    else
        -- Red Sermon mode - costs Life instead
        -- Just check we have some health (>20% to be safe)
        local health_pct = my_utility.get_health_pct()
        if health_pct and health_pct < 0.20 then
            if debug_enabled then console.print("[ZEAL DEBUG] Health too low for Red Sermon mode") end
            return false, 0
        end
    end

    -- Zeal is a melee multi-strike skill, check range
    local melee_range = my_utility.get_melee_range()
    local in_range = my_utility.is_in_range(target, melee_range)
    
    if not in_range then
        if debug_enabled then console.print("[ZEAL DEBUG] Target out of melee range") end
        return false, 0
    end
    
    -- Check min enemies in melee range (Zeal hits multiple times)
    local min_enemies = menu_elements.min_enemies:get()
    if min_enemies > 1 then
        local all_units_count = my_utility.enemy_count_in_radius(melee_range)
        if all_units_count < min_enemies then
            if debug_enabled then console.print("[ZEAL DEBUG] Not enough enemies: " .. all_units_count .. " < " .. min_enemies) end
            return false, 0
        end
    end

    local cooldown = menu_elements.min_cooldown:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end
    
    if cast_spell.target(target, spell_id, 0.0, false) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then
            local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
            console.print("[ZEAL DEBUG] Cast successful - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
        end
        return true, cooldown
    end

    if debug_enabled then console.print("[ZEAL DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
