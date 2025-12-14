-- Consecration - Justice Skill (Judicator/Defensive)
-- Cooldown: 18s | Lucky Hit: 12%
-- Bathe in the Light for 6 seconds, Healing you and allies for 4% Max Life per second and damaging enemies for 75% damage per second.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_consecration_enabled")),
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
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        return false, 0 
    end

    local player = get_local_player()
    if not player then
        return false, 0
    end

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
            local consecration_range_sqr = consecration_range * consecration_range
            local min_enemies = menu_elements.min_enemies_for_damage:get()
            local enemy_type_filter = menu_elements.enemy_type_filter:get()
            
            local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
            local near = 0
            local has_priority_target = false

            for _, e in ipairs(enemies) do
                local is_enemy = false
                if e then
                    local ok, res = pcall(function() return e:is_enemy() end)
                    is_enemy = ok and res or false
                end
                if is_enemy then
                    -- Filter out dead, immune, and untargetable targets per API guidelines
                    local is_dead = false
                    local is_immune = false
                    local is_untargetable = false
                    local ok_dead, res_dead = pcall(function() return e:is_dead() end)
                    local ok_immune, res_immune = pcall(function() return e:is_immune() end)
                    local ok_untarget, res_untarget = pcall(function() return e:is_untargetable() end)
                    is_dead = ok_dead and res_dead or false
                    is_immune = ok_immune and res_immune or false
                    is_untargetable = ok_untarget and res_untarget or false
                    if is_dead or is_immune or is_untargetable then
                        goto continue_consecration
                    end

                    local pos = e:get_position()
                    if pos and pos:squared_dist_to_ignore_z(player_pos) <= consecration_range_sqr then
                        near = near + 1
                        -- Check for priority targets based on filter
                        if enemy_type_filter == 2 then
                            local ok, res = pcall(function() return e:is_boss() end)
                            if ok and res then has_priority_target = true end
                        elseif enemy_type_filter == 1 then
                            local ok_elite, res_elite = pcall(function() return e:is_elite() end)
                            local ok_champ, res_champ = pcall(function() return e:is_champion() end)
                            local ok_boss, res_boss = pcall(function() return e:is_boss() end)
                            if (ok_elite and res_elite) or (ok_champ and res_champ) or (ok_boss and res_boss) then
                                has_priority_target = true
                            end
                        else
                            has_priority_target = true
                        end
                    end
                end
            end

            else
                        has_priority_target = true
                    end
                    ::continue_consecration::
                end
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
        return false, 0
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Consecration is self-cast ground AoE at player position
    if cast_spell and type(cast_spell.self) == "function" then
        if cast_spell.self(spell_id, 0.0) then
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
