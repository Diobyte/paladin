-- Clash - Basic Skill (Juggernaut)
-- Generate Faith: 20 | Lucky Hit: 50%
-- Strike an enemy with your weapon and shield, dealing 115% damage.
-- Physical Damage | Requires Shield

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_clash_enabled")),
    targeting_mode = combo_box:new(4, get_hash("paladin_rotation_clash_targeting_mode")),  -- Default: 4 = Closest Target
    min_cooldown = slider_float:new(0.0, 1.0, 0.08, get_hash("paladin_rotation_clash_min_cd")),  -- Fast generator
    resource_threshold = slider_int:new(0, 100, 30, get_hash("paladin_rotation_clash_resource_threshold")),  -- Only gen when Faith below 30%
}

local spell_id = spell_data.clash.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Clash") then
        menu_elements.main_boolean:render("Enable", "Basic Generator - 115% damage (Generate 20 Faith)")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes, my_utility.targeting_mode_description)
            menu_elements.min_cooldown:render("Min Cooldown", "Minimum time between casts", 2)
            menu_elements.resource_threshold:render("Resource Threshold %", "Only use when Faith BELOW this % (lower = more spender uptime)")
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

    -- GENERATOR LOGIC: Only cast when Faith is LOW
    -- This ensures we prioritize spending Faith on damage skills
    local player = get_local_player()
    if player then
        local current_resource = player:get_primary_resource_current()
        local max_resource = player:get_primary_resource_max()
        if max_resource > 0 then
            local resource_pct = (current_resource / max_resource) * 100
            local threshold = menu_elements.resource_threshold:get()
            
            -- Only generate Faith when BELOW threshold
            if resource_pct >= threshold then
                return false  -- Faith is high enough, let spenders handle it
            end
        end
    end

    -- Clash is a melee skill, check range
    local melee_range = my_utility.get_melee_range()
    local in_range = my_utility.is_in_range(target, melee_range)
    
    if not in_range then
        -- Out of range - movement handled by main.lua
        return false
    end

    if cast_spell.target(target, spell_id, 0.0, false) then
        local current_time = get_time_since_inject()
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast
        local mode_name = my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "Unknown"
        console.print("Cast Clash - Mode: " .. mode_name .. " - Target: " .. target:get_skin_name())
        return true
    end

    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
