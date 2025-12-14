-- Heaven's Fury - Ultimate Skill (Judicator)
-- Cooldown: 30s | Lucky Hit: 2.8%
-- Grasp the Light, dealing 200% damage around you per second before releasing it to seek Nearby enemies and dealing 60% damage per hit for 7 seconds.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_heavens_fury_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_heavens_fury_debug_mode")),
    min_cooldown = slider_float:new(0.0, 40.0, 0.5, get_hash("paladin_rotation_heavens_fury_min_cd")),  -- React fast when ult is up
    engage_range = slider_float:new(4.0, 15.0, 10.0, get_hash("paladin_rotation_heavens_fury_engage_range")),  -- AoE check radius
    min_enemies = slider_int:new(1, 15, 1, get_hash("paladin_rotation_heavens_fury_min_enemies")),  -- 1 = use on any pack
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_heavens_fury_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_heavens_fury_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 10.0, get_hash("paladin_rotation_heavens_fury_min_weight")),
}

local spell_id = spell_data.heavens_fury.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Heaven's Fury") then
        menu_elements.main_boolean:render("Enable", "Ultimate - 200%/s AoE + 60% seeking beams (CD: 30s)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.engage_range:render("Engage Range", "Radius to check for enemies before casting", 1)
            menu_elements.min_enemies:render("Min Enemies", "Minimum enemies nearby to cast")
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics()
    local debug_enabled = menu_elements.debug_mode:get()
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then
        if debug_enabled then console.print("[HEAVENS FURY DEBUG] Spell not allowed") end
        return false, 0
    end

    -- Heaven's Fury starts with AoE around player - check enemies nearby
    local player = get_local_player()
    if not player then return false, 0 end
    
    local player_pos = player:get_position()
    if not player_pos then return false, 0 end
    
    -- Check for nearby enemies using configurable engage range
    local engage_range = menu_elements.engage_range:get()
    local min_enemies = menu_elements.min_enemies:get()
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    
    local enemies = actors_manager.get_enemy_npcs()
    local near = 0
    local has_priority_target = false
    local engage_range_sqr = engage_range * engage_range

    for _, e in ipairs(enemies) do
        if e and e:is_enemy() then
            -- Filter out dead, immune, and untargetable targets
            if e:is_dead() or e:is_immune() or e:is_untargetable() then
                goto continue_heavens_fury
            end

            local pos = e:get_position()
            if pos and pos:squared_dist_to_ignore_z(player_pos) <= engage_range_sqr then
                near = near + 1
                -- Check for priority targets based on filter
                if enemy_type_filter == 2 then
                    if e:is_boss() then has_priority_target = true end
                elseif enemy_type_filter == 1 then
                    if e:is_elite() or e:is_champion() or e:is_boss() then
                        has_priority_target = true
                    end
                else
                    has_priority_target = true
                end
            end
            ::continue_heavens_fury::
        end
    end

    -- Check enemy type filter
    if enemy_type_filter > 0 and not has_priority_target then
        if debug_enabled then console.print("[HEAVENS FURY DEBUG] No priority target found") end
        return false, 0
    end

    if near < min_enemies then
        if debug_enabled then console.print("[HEAVENS FURY DEBUG] Not enough enemies: " .. near .. " < " .. min_enemies) end
        return false, 0
    end

    local cooldown = menu_elements.min_cooldown:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end

    if cast_spell.self(spell_id, 0.0) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then console.print("[HEAVENS FURY DEBUG] Cast successful - Enemies: " .. near) end
        return true, cooldown
    end

    if debug_enabled then console.print("[HEAVENS FURY DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
