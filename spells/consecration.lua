-- Consecration - Justice Skill (Judicator)
-- "Bathe in the Light for 6 seconds, Healing you and your allies for 4.0% Maximum Life per second 
--  and damaging enemies for 75% damage per second"
-- Cooldown: 18 seconds
-- Holy Damage + Defensive/Healing
-- Targeting: cast_spell.self() - Ground AoE at player position

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_consecration_enabled")),
    min_cooldown = slider_float:new(0.0, 25.0, 0.5, get_hash("paladin_rotation_consecration_min_cd")),
    use_for_healing = checkbox:new(true, get_hash("paladin_rotation_consecration_use_healing")),
    health_threshold = slider_int:new(10, 100, 70, get_hash("paladin_rotation_consecration_health_threshold")),
    use_for_damage = checkbox:new(true, get_hash("paladin_rotation_consecration_use_damage")),
    min_enemies_for_damage = slider_int:new(1, 15, 2, get_hash("paladin_rotation_consecration_min_enemies")),
}

local spell_id = spell_data.consecration.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Consecration") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.use_for_healing:render("Use for Healing", "Cast when health drops below threshold")
            if menu_elements.use_for_healing:get() then
                menu_elements.health_threshold:render("Health Threshold (%)", "Cast when health below this")
            end
            menu_elements.use_for_damage:render("Use for Damage", "Cast when enough enemies are nearby")
            if menu_elements.use_for_damage:get() then
                menu_elements.min_enemies_for_damage:render("Min Enemies", "Minimum enemies nearby for damage use")
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
            
            local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
            local near = 0

            for _, e in ipairs(enemies) do
                if e and e:is_enemy() then
                    local pos = e:get_position()
                    if pos and pos:squared_dist_to_ignore_z(player_pos) <= consecration_range_sqr then
                        near = near + 1
                    end
                end
            end

            if near >= min_enemies then
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
