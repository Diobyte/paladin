-- Blessed Hammer - Core Skill (Judicator)
-- Faith Cost: 10 | Lucky Hit: 24%
-- Throw a Blessed Hammer that spirals out, dealing 115% damage.
-- Holy Damage
-- META: "Spam Blessed Hammer to deal damage" - this is THE main skill (maxroll.gg)

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_blessed_hammer_enabled")),
    debug_mode = checkbox:new(false, get_hash("paladin_rotation_blessed_hammer_debug_mode")),
    -- targeting_mode removed to allow self-cast logic to run even without a valid target from main.lua
    min_cooldown = slider_float:new(0.0, 1.0, 0.0, get_hash("paladin_rotation_blessed_hammer_min_cd")),  -- META: 0 = maximum spam rate
    engage_range = slider_float:new(2.0, 25.0, 7.0, get_hash("paladin_rotation_blessed_hammer_engage_range")),  -- Reduced to 7.0 for effective spiral hits
    min_resource = slider_int:new(0, 100, 0, get_hash("paladin_rotation_blessed_hammer_min_resource")),  -- 0 = spam freely (meta)
    min_enemies = slider_int:new(1, 15, 1, get_hash("paladin_rotation_blessed_hammer_min_enemies")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_blessed_hammer_enemy_type")),
    -- Optional pack-size gate to avoid wasting casts on single stragglers
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_blessed_hammer_use_min_weight")),
    minimum_weight = slider_float:new(1.0, 15.0, 3.0, get_hash("paladin_rotation_blessed_hammer_min_weight")),
}

local spell_id = spell_data.blessed_hammer.spell_id
local next_time_allowed_cast = 0.0
-- Movement is now handled by my_utility.move_to_target() centralized system

local function menu()
    if menu_elements.tree_tab:push("Blessed Hammer") then
        menu_elements.main_boolean:render("Enable", "Core Skill - Spiraling hammer (Faith Cost: 10)")
        if menu_elements.main_boolean:get() then
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for this spell")
            -- menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, my_utility.targeting_mode_description)
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.engage_range:render("Engage Range", "Max distance to enemies for casting", 1)
            menu_elements.min_resource:render("Min Resource %", "Only cast when Faith above this % (0 = spam freely)")
            menu_elements.min_enemies:render("Min Enemies to Cast", "Minimum number of enemies nearby to cast")
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Require Pack Size", "Only cast when at least N enemies are in range")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Pack Size", "Minimum enemies in range before casting", 1)
            end
        end
        menu_elements.tree_tab:pop()
    end
end

-- Optional target allows main.lua to pass the evaluated target; we still self-cast.
local function logics(target)
    local debug_enabled = menu_elements.debug_mode:get()
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then
        -- if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Spell not allowed") end
        return false, 0
    end

    local player = get_local_player()
    if not player then return false, 0 end
    
    local player_pos = player:get_position()
    if not player_pos then return false, 0 end
    
    -- Resource check (Faith Cost: 10 - optional, default 0 = spam freely)
    local min_resource = menu_elements.min_resource:get()
    if min_resource > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) < min_resource then
            if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Insufficient Faith") end
            return false, 0
        end
    end
    
    local engage = menu_elements.engage_range:get()

    -- Auto-targeting / Movement System
    -- If target is nil, try to find one from global valid enemies to allow movement
    if not target and _G.PaladinRotation and _G.PaladinRotation.current_target_id then
        -- Try to find the current global target object
        -- Use world.get_game_object(id) as per API documentation
        if world and world.get_game_object then
            local global_target = world.get_game_object(_G.PaladinRotation.current_target_id)
            if global_target and global_target:is_valid() then
                target = global_target
            end
        end
    end

    if target and target:is_enemy() then   
        local in_range = my_utility.is_in_range(target, engage)
        if not in_range then
            my_utility.move_to_target(target:get_position(), target:get_id())
            if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Moving to target - out of engage range (" .. string.format("%.1f", target:get_position():dist_to(player_pos)) .. " > " .. engage .. ")") end
            return false, 0
        end
    end

    local min_enemies = menu_elements.min_enemies:get()
    local use_pack_gate = menu_elements.use_minimum_weight:get()
    local min_pack_size = math.ceil(menu_elements.minimum_weight:get())
    local required_enemies = use_pack_gate and math.max(min_enemies, min_pack_size) or min_enemies
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    
    -- Count enemies in range
    -- OPTIMIZATION: Use cached valid enemies from main.lua if available to avoid re-scanning
    local enemies_list = {}
    if _G.PaladinRotation and _G.PaladinRotation.valid_enemies then
        -- Use the pre-filtered list from main.lua (already filtered by range, dead, immune, floor)
        -- We just need to check the specific engage range for this spell
        for _, data in ipairs(_G.PaladinRotation.valid_enemies) do
            table.insert(enemies_list, data.unit)
        end
    else
        -- Fallback to target_selector or actors_manager
        if target_selector and target_selector.get_near_target_list then
            enemies_list = target_selector.get_near_target_list(player_pos, engage) or {}
        else
            enemies_list = actors_manager.get_enemy_npcs() or {}
        end
    end
    
    local near = 0
    local has_priority_target = false
    local engage_sqr = engage * engage
    
    -- Get floor height threshold from menu (or default to 5.0)
    -- We can access the global menu element if available, or hardcode a reasonable default
    local floor_height_threshold = 5.0
    if menu and menu.menu_elements and menu.menu_elements.floor_height_threshold then
        floor_height_threshold = menu.menu_elements.floor_height_threshold:get()
    end

    for _, e in ipairs(enemies_list) do
        if e and e:is_enemy() then
            -- Filter out dead, immune, and untargetable enemies (if not already filtered)
            -- Note: valid_enemies from main.lua are already filtered for dead/immune/untargetable
            local is_pre_filtered = (_G.PaladinRotation and _G.PaladinRotation.valid_enemies)
            
            if not is_pre_filtered then
                if e:is_dead() or e:is_immune() or e:is_untargetable() then
                    goto continue
                end
            end
            
            local pos = e:get_position()
            if pos and pos:squared_dist_to_ignore_z(player_pos) <= engage_sqr then
                -- Elevation check (if not already filtered)
                if not is_pre_filtered then
                    if math.abs(player_pos:z() - pos:z()) > floor_height_threshold then
                        goto continue
                    end
                end
                
                near = near + 1
                -- Check for priority targets based on filter
                if enemy_type_filter == 2 then
                    -- Boss only
                    if e:is_boss() then has_priority_target = true end
                elseif enemy_type_filter == 1 then
                    -- Elite/Champion/Boss
                    if e:is_elite() or e:is_champion() or e:is_boss() then
                        has_priority_target = true
                    end
                else
                    has_priority_target = true  -- Any enemy counts
                end
            end
        end
        ::continue::
    end

    -- Check enemy type filter (must have at least one priority target in range)
    if enemy_type_filter > 0 and not has_priority_target then
        if debug_enabled then console.print("[BLESSED HAMMER DEBUG] No priority target found") end
        return false, 0
    end

    if near < required_enemies then
        -- CENTRALIZED MOVEMENT: Let main.lua handle movement if no spell is cast
        -- We return false here so the rotation can try other spells (e.g. mobility/buffs)
        -- If no other spell casts, main.lua will move us to the target
        if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Not enough enemies in range (" .. near .. " < " .. required_enemies .. ")") end
        return false, 0
    end

    local cooldown = menu_elements.min_cooldown:get()
    if cooldown < my_utility.spell_delays.regular_cast then
        cooldown = my_utility.spell_delays.regular_cast
    end

    -- Try targeted cast first if we have a target (more reliable for "attack" actions)
    -- Fallback to self-cast if no target or targeted cast fails
    local cast_success = false
    if target and cast_spell.target(target, spell_id, 0.0, false) then
        cast_success = true
        if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Cast TARGET successful - ID: " .. spell_id) end
    elseif cast_spell.self(spell_id, 0.0) then
        cast_success = true
        if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Cast SELF successful - ID: " .. spell_id) end
    end

    if cast_success then
        local current_time = my_utility.safe_get_time()
        next_time_allowed_cast = current_time + cooldown
        if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Cast successful - Enemies: " .. near) end
        return true, cooldown
    end

    if debug_enabled then console.print("[BLESSED HAMMER DEBUG] Cast failed - ID: " .. spell_id) end
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
