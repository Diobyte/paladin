local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 12.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "shield_charge_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "shield_charge_targeting_mode")),
    min_target_range    = slider_float:new(0, max_spell_range - 1, 0,
        get_hash(my_utility.plugin_label .. "shield_charge_min_target_range")),
    elites_only         = checkbox:new(false, get_hash(my_utility.plugin_label .. "shield_charge_elites_only")),
    cast_delay          = slider_float:new(0.01, 1.0, 0.1, get_hash(my_utility.plugin_label .. "shield_charge_cast_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Shield Charge") then
        menu_elements.main_boolean:render("Enable Shield Charge", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    if not target then return false end;
    if menu_elements.elites_only:get() and not target:is_elite() then return false end
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.shield_charge.spell_id);

    if not is_logic_allowed then return false end;

    if not my_utility.is_in_range(target, max_spell_range) then
        return false
    end

    -- Logic:
    -- 1. If outside min_range (Gap Close): Cast immediately.
    -- 2. If inside min_range (Boss DPS): Cast only if recast_delay has passed.
    local is_in_min_range = my_utility.is_in_range(target, menu_elements.min_target_range:get())
    
    if is_in_min_range then
        -- We are in melee range (Boss logic)
        if not target:is_boss() then return false end
        
        local current_time = get_time_since_inject()
        local last_cast = my_utility.get_last_cast_time("shield_charge")
        if current_time < last_cast + 2.0 then -- Hardcoded 2.0s delay for Shield Charge weaving
            return false
        end
    end

    if cast_spell.position(spell_data.shield_charge.spell_id, target:get_position(), 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + menu_elements.cast_delay:get();
        console.print("Cast Shield Charge - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
        return true;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type
}
