local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local menu_module = require("menu")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_evade_enabled")),
    min_cooldown = slider_float:new(0.0, 2.0, 0.15, get_hash("paladin_rotation_evade_min_cd")),
}

local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Evade") then
        menu_elements.main_boolean:render("Enable", "")
        if menu_elements.main_boolean:get() then
            menu_elements.min_cooldown:render("Min Cooldown", "", 2)
        end
        menu_elements.tree_tab:pop()
    end
end

local function logics(best_target, area_analysis)
    if not menu_elements.main_boolean:get() then return false end

    local now = my_utility.safe_get_time()
    if now < next_time_allowed_cast then return false end

    local spell_id = spell_data.evade.spell_id
    if not my_utility.is_spell_ready(spell_id) then
        return false
    end

    local dest = nil

    -- Smart: prefer cursor if available, else target
    if type(get_cursor_position) == "function" then
        dest = get_cursor_position()
    end
    if (not dest or (dest.is_zero and dest:is_zero())) and best_target and best_target:is_enemy() then
        dest = best_target:get_position()
    end

    if not dest then return false end

    if cast_spell and type(cast_spell.position) == "function" then
        if cast_spell.position(spell_id, dest, 0.0) then
            next_time_allowed_cast = now + menu_elements.min_cooldown:get()
            _G.paladin_rotation_last_evade_time = now
            return true
        end
    end

    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
}
