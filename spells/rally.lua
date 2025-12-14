-- Rally - Valor Skill (Zealot)
-- Charges: 3 | Cooldown: 16s
-- Rally forth, gaining 20% Movement Speed for 8 seconds and generate 22 Faith.

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_rally_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_rally_debug_mode")),
    recast_interval = slider_float:new(0.5, 30.0, 2.0, get_hash("paladin_rotation_rally_min_cd")),  -- META: Use often! Reduced from 4.0
    resource_threshold = slider_int:new(0, 100, 80, get_hash("paladin_rotation_rally_resource_threshold")),  -- Higher threshold = use more often as gen
    use_for_movespeed = checkbox:new(true, get_hash("paladin_rotation_rally_use_movespeed")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_rally_enemy_type")),
}

local spell_id = spell_data.rally.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Rally") then
        menu_elements.main_boolean:render("Enable", "Generate 22 Faith + 20% Move Speed for 8s (3 charges)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.recast_interval:render("Recast Interval", "Time between uses", 2)
            menu_elements.use_for_movespeed:render("Use for Move Speed", "Always use Rally for move speed buff (meta recommends)")
            menu_elements.resource_threshold:render("Resource Threshold %", "Only use when Faith BELOW this % (ignored if Move Speed mode enabled)")
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics()
    local debug_enabled = menu_elements.debug_mode:get()
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then
        if debug_enabled then console.print("[RALLY DEBUG] Spell not allowed") end
        return false, 0
    end

    local player = get_local_player()
    if not player then return false, 0 end
    
    local player_pos = player:get_position()
    if not player_pos then return false, 0 end
    
    local use_for_movespeed = menu_elements.use_for_movespeed:get()

    -- Check for enemies nearby unless we are using Rally purely for mobility
    local nearby = my_utility.enemy_count_in_radius(25.0, player_pos)
    if (not use_for_movespeed) and nearby == 0 then
        if debug_enabled then console.print("[RALLY DEBUG] No enemies nearby") end
        return false, 0
    end

    -- Enemy type filter check
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    if (not use_for_movespeed) and enemy_type_filter > 0 then
        local enemies_list = {}
        if _G.PaladinRotation and _G.PaladinRotation.valid_enemies then
            for _, data in ipairs(_G.PaladinRotation.valid_enemies) do
                table.insert(enemies_list, data.unit)
            end
        else
            enemies_list = actors_manager.get_enemy_npcs() or {}
        end

        local has_priority_target = false
        local check_range_sqr = 25.0 * 25.0
        
        for _, e in ipairs(enemies_list) do
            if e and e:is_enemy() then
                -- Filter out dead, immune, and untargetable targets
                if not (_G.PaladinRotation and _G.PaladinRotation.valid_enemies) then
                    if e:is_dead() or e:is_immune() or e:is_untargetable() then
                        goto continue_rally
                    end
                end

                local pos = e:get_position()
                if pos and pos:squared_dist_to_ignore_z(player_pos) <= check_range_sqr then
                    if enemy_type_filter == 2 then
                        if e:is_boss() then has_priority_target = true; break end
                    elseif enemy_type_filter == 1 then
                        if e:is_elite() or e:is_champion() or e:is_boss() then
                            has_priority_target = true; break
                        end
                    end
                end
            end
            ::continue_rally::
        end
        
        if not has_priority_target then
            if debug_enabled then console.print("[RALLY DEBUG] No priority target found") end
            return false, 0
        end
    end

    -- META BUILD: Rally should be used "as often as possible" for move speed
    
    if not use_for_movespeed then
        -- GENERATOR LOGIC: Only cast when Faith is LOW
        local threshold = menu_elements.resource_threshold:get()
        if threshold > 0 then
            local current_resource = player:get_primary_resource_current()
            local max_resource = player:get_primary_resource_max()
            if max_resource > 0 then
                local resource_pct = (current_resource / max_resource) * 100
                if resource_pct >= threshold then
                    if debug_enabled then console.print("[RALLY DEBUG] Faith too high") end
                    return false, 0  -- Faith is high enough, skip
                end
            end
        end
    end

    local cooldown = menu_elements.recast_interval:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end

    if cast_spell.self(spell_id, 0.0) then
        local current_time = my_utility.safe_get_time()
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then console.print("[RALLY DEBUG] Cast successful") end
        return true, cooldown
    end

    if debug_enabled then console.print("[RALLY DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
