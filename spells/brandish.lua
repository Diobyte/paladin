-- Brandish - Basic Skill (Disciple)
-- Generate Faith: 14 | Lucky Hit: 20%
-- Brandish the Light, unleashing an arc that deals 75% damage.
-- Holy Damage

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_brandish_enabled")),
    min_cooldown = slider_float:new(0.0, 5.0, 0.08, get_hash("paladin_rotation_brandish_min_cd")),  -- Fast backup generator
    resource_threshold = slider_int:new(0, 100, 25, get_hash("paladin_rotation_brandish_resource_threshold")),  -- Only when Faith very low (backup)
}

local spell_id = spell_data.brandish.spell_id
local next_time_allowed_cast = 0.0
local next_time_allowed_move = 0.0
local move_delay = 0.5  -- Delay between movement commands (match druid script)

local function menu()
    if menu_elements.tree_tab:push("Brandish") then
        menu_elements.main_boolean:render("Enable", "Basic Generator - Arc for 75% (Generate 14 Faith)")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.resource_threshold:render("Resource Threshold %", "Only use when Faith BELOW this % (backup generator)")
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)
    if not target then return false end
    
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then return false end

    -- Validate target (Druid pattern - simple checks)
    if not target:is_enemy() then return false end
    if target:is_dead() or target:is_immune() or target:is_untargetable() then return false end

    -- GENERATOR LOGIC: Only cast when Faith is LOW (backup generator)
    local threshold = menu_elements.resource_threshold:get()
    if threshold > 0 then
        local resource_pct = my_utility.get_resource_pct()
        if resource_pct and (resource_pct * 100) >= threshold then
            return false  -- Faith is high enough, let spenders handle it
        end
    end

    -- Range check for melee (Brandish has slightly longer arc range)
    local cast_range = 4.0
    local in_range = my_utility.is_in_range(target, cast_range)
    
    if not in_range then
        -- Out of range - move toward target with throttling (Druid pattern)
        local current_time = get_time_since_inject()
        if current_time >= next_time_allowed_move then
            local target_pos = target:get_position()
            pathfinder.force_move_raw(target_pos)
            next_time_allowed_move = current_time + move_delay
        end
        return false
    end

    if cast_spell.target(target, spell_id, 0.0, false) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast
        console.print("Cast Brandish - Target: " .. target:get_skin_name())
        return true
    end

    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
