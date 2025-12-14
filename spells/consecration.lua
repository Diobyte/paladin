-- Consecration - Justice Skill (Judicator/Defensive)
-- Cooldown: 18s | Lucky Hit: 12%
-- Bathe in the Light for 6 seconds, Healing you and allies for 4% Max Life per second and damaging enemies for 75% damage per second.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_consecration_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_consecration_debug_mode")),
    min_cooldown = slider_float:new(0.0, 25.0, 0.2, get_hash("paladin_rotation_consecration_min_cd")),  -- Fast burst
    use_for_healing = checkbox:new(true, get_hash("paladin_rotation_consecration_use_healing")),
    health_threshold = slider_int:new(10, 100, 60, get_hash("paladin_rotation_consecration_health_threshold")),  -- Lower threshold = use more proactively
    use_for_damage = checkbox:new(true, get_hash("paladin_rotation_consecration_use_damage")),
    min_enemies_for_damage = slider_int:new(1, 15, 1, get_hash("paladin_rotation_consecration_min_enemies")),  -- 1 = always use for damage
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_consecration_enemy_type")),
}

local spell_id = spell_data.consecration.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Consecration") then
        menu_elements.main_boolean:render("Enable", "Justice - 4% Life/s heal + 75%/s damage + Weaken (CD: 18s)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.use_for_healing:render("Use for Healing", "Cast when health drops below threshold")
            if menu_elements.use_for_healing:get() then
                menu_elements.health_threshold:render("Health Threshold (%)", "Cast when health below this")
            end
            menu_elements.use_for_damage:render("Use for Damage", "Cast when enemies are nearby (drop on bosses/elites)")
            if menu_elements.use_for_damage:get() then
                menu_elements.min_enemies_for_damage:render("Min Enemies", "Minimum enemies nearby for damage use (1 = always)")
                menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "Only use for damage on these target types")
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
        if debug_enabled then console.print("[CONSECRATION DEBUG] Spell not allowed") end
        return false, 0
    end

    local player = get_local_player()
    if not player then return false, 0 end

    local should_cast = false
    
    -- Check healing condition
    if menu_elements.use_for_healing:get() then
        local current_health = player:get_current_health()
        local max_health = player:get_max_health()
        if current_health and max_health and max_health > 0 then
            local health_pct = (current_health / max_health) * 100
            if health_pct < menu_elements.health_threshold:get() then
                should_cast = true
            end
        end
    end
    
    -- Check damage condition (enemies nearby)
    if not should_cast and menu_elements.use_for_damage:get() then
        local player_pos = player:get_position()
        if player_pos then
            local consecration_range = 6.0 -- Approximate Consecration radius
            local min_enemies = menu_elements.min_enemies_for_damage:get()
            local enemy_type_filter = menu_elements.enemy_type_filter:get()
            
            local enemies = actors_manager.get_enemy_npcs()
            local near = 0
            local has_priority_target = false
            local consecration_range_sqr = consecration_range * consecration_range

            for _, e in ipairs(enemies) do
                if e and e:is_enemy() then
                    -- Filter out dead, immune, and untargetable targets
                    if e:is_dead() or e:is_immune() or e:is_untargetable() then
                        goto continue_consecration
                    end

                    local pos = e:get_position()
                    if pos and pos:squared_dist_to_ignore_z(player_pos) <= consecration_range_sqr then
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
                end
                ::continue_consecration::
            end

            -- Check enemy type filter (must have priority target for damage use)
            if enemy_type_filter > 0 and not has_priority_target then
                -- No priority target, skip damage-based cast
            elseif near >= min_enemies then
                should_cast = true
            end
        end
    end
    
    if not should_cast then
        if debug_enabled then console.print("[CONSECRATION DEBUG] Conditions not met for cast") end
        return false, 0
    end

    local cooldown = menu_elements.min_cooldown:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end

    if cast_spell.self(spell_id, 0.0) then
        local current_time = my_utility.safe_get_time()
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then console.print("[CONSECRATION DEBUG] Cast successful - Healing/Damage AoE") end
        return true, cooldown
    end

    if debug_enabled then console.print("[CONSECRATION DEBUG] Cast failed") end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
