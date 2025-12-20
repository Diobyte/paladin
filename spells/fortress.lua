local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0 -- Self-cast
local menu_elements =
{
    tree_tab       = tree_node:new(1),
    main_boolean   = checkbox:new(true, get_hash(my_utility.plugin_label .. "fortress_main_bool_base")),
    hp_threshold   = slider_float:new(0.0, 1.0, 0.4, get_hash(my_utility.plugin_label .. "fortress_hp_threshold")),
    use_on_cc      = checkbox:new(true, get_hash(my_utility.plugin_label .. "fortress_use_on_cc")),
    force_priority = checkbox:new(true, get_hash(my_utility.plugin_label .. "fortress_force_priority")),
}

local function menu()
    if menu_elements.tree_tab:push("Fortress") then
        menu_elements.main_boolean:render("Enable Spell", "Create defensive area that grants immunity and resolve stacks")

        if menu_elements.main_boolean:get() then
            menu_elements.hp_threshold:render("HP Threshold", "Cast when HP is below this percent (0.0 - 1.0)", 2)
            menu_elements.use_on_cc:render("Use on CC", "Cast when Crowd Controlled (Stunned, Frozen, etc.)")
            menu_elements.force_priority:render("Force Priority", "Always cast on Boss/Elite/Champion (if applicable)")
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    -- Fortress is a self-cast fortification ultimate
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast,
        spell_data.fortress.spell_id);
    if not is_logic_allowed then return false end;

    local local_player = get_local_player()
    local current_hp_pct = local_player:get_current_health() / local_player:get_max_health()
    local hp_threshold = menu_elements.hp_threshold:get()
    local use_on_cc = menu_elements.use_on_cc:get()
    -- local is_cc = my_utility.is_crowd_controlled(local_player)

    if current_hp_pct > hp_threshold then -- and not (use_on_cc and is_cc) then
        return false
    end

    if cast_spell.self(spell_data.fortress.spell_id, 0) then
        local current_time = get_time_since_inject();
        local cast_delay = 0.1;
        next_time_allowed_cast = current_time + cast_delay;
        console.print("Cast Fortress - Defensive area activated");
        return true, cast_delay;
    end;

    return false;
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
