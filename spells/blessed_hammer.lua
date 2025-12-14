local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_blessed_hammer_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.1, get_hash("paladin_rotation_blessed_hammer_min_cd")),
    engage_range = slider_float:new(2.0, 25.0, 12.0, get_hash("paladin_rotation_blessed_hammer_engage_range")),
    min_enemies = slider_int:new(1, 15, 1, get_hash("paladin_rotation_blessed_hammer_min_enemies")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_blessed_hammer_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_blessed_hammer_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_blessed_hammer_min_weight")),
}

local spell_id = spell_data.blessed_hammer.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Blessed Hammer") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.engage_range:render("Engage Range", "", 1)
            menu_elements.min_enemies:render("Min Enemies to Cast", "Minimum number of enemies nearby to cast")
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
        return false, 0 
    end

    local player = get_local_player()
    local player_pos = player and player:get_position() or nil
    if not player_pos then
        return false, 0
    end
    
    local engage = menu_elements.engage_range:get()
    local engage_sqr = engage * engage
    local min_enemies = menu_elements.min_enemies:get()
    
    -- Count enemies in range (like barb's HotA min targets)
    local enemies = actors_manager and actors_manager.get_enemy_npcs and actors_manager.get_enemy_npcs() or {}
    local near = 0

    for _, e in ipairs(enemies) do
        if e and e:is_enemy() then
            local pos = e:get_position()
            if pos and pos:squared_dist_to_ignore_z(player_pos) <= engage_sqr then
                near = near + 1
            end
        end
    end

    if near < min_enemies then
        return false, 0
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Cast at self (AoE spiral around player) - this is how Blessed Hammer works
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
