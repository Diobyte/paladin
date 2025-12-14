-- Condemn - Justice Skill (Disciple)
-- Cooldown: 15s | Lucky Hit: 26%
-- Harness the Light and Pull enemies in after 1.5 seconds, briefly Stunning them and dealing 240% damage.
-- Holy Damage
-- META CRITICAL: "Use Condemn to pull enemies in" + ARBITER TRIGGER via Disciple Oath
-- Essential for grouping enemies AND maintaining Arbiter form!

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_condemn_enabled")),
    min_cooldown = slider_float:new(0.0, 20.0, 0.15, get_hash("paladin_rotation_condemn_min_cd")),  -- META: ARBITER TRIGGER - cast ASAP when available
    pull_range = slider_float:new(4.0, 12.0, 8.0, get_hash("paladin_rotation_condemn_pull_range")),  -- Condemn AoE radius
    min_enemies = slider_int:new(1, 15, 1, get_hash("paladin_rotation_condemn_min_enemies")),  -- 1 = always cast for Arbiter, even single target
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_condemn_enemy_type")),  -- 0 = All (Arbiter form is the priority)
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_condemn_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 8.0, get_hash("paladin_rotation_condemn_min_weight")),
}

local spell_id = spell_data.condemn.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Condemn") then
        menu_elements.main_boolean:render("Enable", "ARBITER TRIGGER - Pull + Stun + 240% (CD: 15s)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "Lower = more Arbiter uptime (CRITICAL)", 2)
            menu_elements.pull_range:render("Pull Range", "Radius to check for enemies before casting", 1)
            menu_elements.min_enemies:render("Min Enemies", "Minimum enemies nearby to cast (1 = always)")
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
    
    if not is_logic_allowed then return false end

    -- Condemn is self-centered AoE - check enemies around player
    local player = get_local_player()
    if not player then return false end
    
    local player_pos = player:get_position()
    if not player_pos then return false end
    
    -- Count nearby enemies (Condemn has configurable pull radius)
    local condemn_range = menu_elements.pull_range:get()
    local min_enemies = menu_elements.min_enemies:get()
    local enemy_type_filter = menu_elements.enemy_type_filter:get()
    
    local enemies = actors_manager.get_enemy_npcs()
    local near = 0
    local has_priority_target = false
    local condemn_range_sqr = condemn_range * condemn_range

    for _, e in ipairs(enemies) do
        if e and e:is_enemy() then
            -- Filter out dead, immune, and untargetable enemies
            if e:is_dead() or e:is_immune() or e:is_untargetable() then
                goto continue
            end
            
            local pos = e:get_position()
            if pos and pos:squared_dist_to_ignore_z(player_pos) <= condemn_range_sqr then
                near = near + 1
                -- Check for priority targets based on filter
                if enemy_type_filter == 2 then
                    if e:is_boss() then has_priority_target = true end
                elseif enemy_type_filter == 1 then
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
        return false
    end

    if near < min_enemies then return false end

    if cast_spell.self(spell_id, 0.0) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast
        console.print("Cast Condemn - Enemies pulled: " .. near)
        return true
    end

    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
