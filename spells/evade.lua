local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local menu_module = require("menu")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_evade_enabled")),
    min_cooldown = slider_float:new(0.0, 2.0, 0.15, get_hash("paladin_rotation_evade_min_cd")),
    evade_mode = combo_box:new(0, get_hash("paladin_rotation_evade_mode")),
}

local spell_id = spell_data.evade.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Evade") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
            menu_elements.evade_mode:render("Evade Mode", {"Cursor", "Target", "Smart (Cursor > Target)"}, "Where to evade to")
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(best_target, area_analysis)
    local menu_boolean = menu_elements.main_boolean:get()
    if not menu_boolean then
        return false, 0
    end
    
    -- Check basic readiness without the evade dangerous position check
    -- since evade itself can be used TO escape dangerous positions
    local current_time = my_utility.safe_get_time()
    if current_time < next_time_allowed_cast then
        return false, 0
    end
    
    if not my_utility.is_spell_ready(spell_id) then
        return false, 0
    end
    
    if not my_utility.is_spell_affordable(spell_id) then
        return false, 0
    end
    
    -- Check if we're in danger - if so, use evade defensively
    local player = get_local_player()
    if not player then
        return false, 0
    end
    
    local player_pos = player:get_position()
    local is_dangerous = evade and evade.is_dangerous_position and evade.is_dangerous_position(player_pos)
    
    -- If not in danger, don't use evade (let core module handle offensive evades if needed)
    -- This prevents wasting evade charges
    if not is_dangerous then
        return false, 0
    end

    local dest = nil
    local evade_mode = menu_elements.evade_mode:get()
    
    -- 0: Cursor, 1: Target, 2: Smart (Cursor > Target)
    if evade_mode == 0 then
        -- Cursor only
        if type(get_cursor_position) == "function" then
            dest = get_cursor_position()
        end
    elseif evade_mode == 1 then
        -- Target only
        if best_target and best_target:is_enemy() then
            dest = best_target:get_position()
        end
    else
        -- Smart: prefer cursor if available, else target
        if type(get_cursor_position) == "function" then
            dest = get_cursor_position()
        end
        if (not dest or (dest.is_zero and dest:is_zero())) and best_target and best_target:is_enemy() then
            dest = best_target:get_position()
        end
    end

    if not dest then 
        return false, 0 
    end

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    if cast_spell and type(cast_spell.position) == "function" then
        if cast_spell.position(spell_id, dest, 0.0) then
            next_time_allowed_cast = now + cooldown
            _G.paladin_rotation_last_evade_time = now
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
