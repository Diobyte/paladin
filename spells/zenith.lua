-- Zenith - Ultimate Skill (Zealot)
-- Cooldown: 25s | Lucky Hit: 28%
-- Summon a divine sword that cleaves the battlefield for 450% damage. Casting Zenith again cuts through for 400% damage and Knocks Down enemies for 2 seconds.
-- Physical Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_zenith_enabled")),
    min_cooldown = slider_float:new(0.0, 30.0, 0.3, get_hash("paladin_rotation_zenith_min_cd")),  -- React fast when ult is up
    melee_range = slider_float:new(2.0, 8.0, 5.0, get_hash("paladin_rotation_zenith_melee_range")),  -- Cleave AoE radius
    min_enemies = slider_int:new(1, 15, 1, get_hash("paladin_rotation_zenith_min_enemies")),  -- 1 = use on any target
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_zenith_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_zenith_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 8.0, get_hash("paladin_rotation_zenith_min_weight")),
}

local spell_id = spell_data.zenith.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Zenith") then
        menu_elements.main_boolean:render("Enable", "Ultimate - 450% cleave, recast 400% + Knockdown (CD: 25s)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.melee_range:render("Melee Range", "Radius to check for enemies before casting", 1)
            menu_elements.min_enemies:render("Min Enemies", "Minimum enemies in melee range to cast")
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
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        return false
    end

    -- Zenith is a melee AoE cleave - check for enemies in melee range
    local player = get_local_player()
    if not player then return false end
    
    local player_pos = player:get_position()
    if not player_pos then return false end
    
    -- Zenith has configurable melee/short range cleave
    local melee_range = menu_elements.melee_range:get()
    local melee_range_sqr = melee_range * melee_range
    local min_enemies = menu_elements.min_enemies:get()
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    
    local enemies = actors_manager.get_enemy_npcs()
    local near = 0
    local has_priority_target = false

    for _, e in ipairs(enemies) do
        if e and e:is_enemy() then
            -- Filter out dead, immune, and untargetable targets per API guidelines
            if e:is_dead() or e:is_immune() or e:is_untargetable() then
                goto continue_zenith
            end

            local pos = e:get_position()
            if pos and pos:squared_dist_to_ignore_z(player_pos) <= melee_range_sqr then
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
            ::continue_zenith::
        end
    end

    -- Check enemy type filter
    if enemy_type_filter > 0 and not has_priority_target then
        return false
    end

    if near < min_enemies then
        return false
    end

    -- Zenith is self-cast melee AoE cleave
    if cast_spell.self(spell_id, 0.0) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast
        console.print("Cast Zenith - Enemies: " .. near)
        return true
    end

    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
