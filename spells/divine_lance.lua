local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 15.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "divine_lance_main_bool_base")),
    targeting_mode      = combo_box:new(0, get_hash(my_utility.plugin_label .. "divine_lance_targeting_mode")),
    min_target_range    = slider_float:new(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "divine_lance_min_target_range")),
    elites_only         = checkbox:new(false, get_hash(my_utility.plugin_label .. "divine_lance_elites_only")),
    self_timer          = checkbox:new(false, get_hash(my_utility.plugin_label .. "divine_lance_self_timer")),
    self_timer_delay    = slider_float:new(0.01, 2.0, my_utility.spell_delays.divine_lance, get_hash(my_utility.plugin_label .. "divine_lance_self_timer_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Divine Lance") then
        menu_elements.main_boolean:render("Enable Divine Lance", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
            menu_elements.self_timer:render("Self Timer", "Enable independent timing (removes from main rotation)")
            if menu_elements.self_timer:get() then
                menu_elements.self_timer_delay:render("Self Timer Delay", "Time between casts when self-timed", 2)
            end
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    if not target then return false end;
    if menu_elements.elites_only:get() and not target:is_elite() then return false end
    
    local menu_boolean = menu_elements.main_boolean:get();
    local current_time = get_time_since_inject();
    
    -- Handle self-timer mode
    if menu_elements.self_timer:get() then
        -- Self-timed: bypass main rotation, use own timer
        if current_time < next_time_allowed_cast then
            return false;
        end
    else
        -- Rotation mode: use main spell_allowed check with centralized delay
        local is_logic_allowed = my_utility.is_spell_allowed(
            menu_boolean,
            next_time_allowed_cast,
            spell_data.divine_lance.spell_id);

        if not is_logic_allowed then return false end;
    end

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        return false
    end

    if cast_spell.target(target, spell_data.divine_lance.spell_id, 0, false) then
        -- Set next cast time based on mode
        if menu_elements.self_timer:get() then
            next_time_allowed_cast = current_time + menu_elements.self_timer_delay:get();
            console.print("Divine Lance (Self-Timed) - Delay: " .. string.format("%.2f", menu_elements.self_timer_delay:get()) .. "s");
        else
            next_time_allowed_cast = current_time + my_utility.spell_delays.divine_lance;
            console.print("Divine Lance (Rotation)");
        end
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
