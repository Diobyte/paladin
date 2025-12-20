local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
<<<<<<< Updated upstream
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "rally_main_bool_base")),
    cast_on_cooldown    = checkbox:new(false, get_hash(my_utility.plugin_label .. "rally_cast_on_cooldown")),
    cast_delay          = slider_float:new(0.01, 10.0, 0.1,
=======
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(true, get_hash(my_utility.plugin_label .. "rally_main_bool_base")),
    cast_on_cooldown = checkbox:new(false, get_hash(my_utility.plugin_label .. "rally_cast_on_cooldown")),
    cast_delay       = slider_float:new(0.01, 10.0, 0.1,
>>>>>>> Stashed changes
        get_hash(my_utility.plugin_label .. "rally_cast_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Rally") then
        menu_elements.main_boolean:render("Enable Spell", "Enable or disable this spell")

        if menu_elements.main_boolean:get() then
<<<<<<< Updated upstream
            menu_elements.cast_on_cooldown:render("Cast on Cooldown", "Always cast when ready (maintains buff constantly)")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
=======
<<<<<<< Updated upstream
            menu_elements.hp_threshold:render("HP Threshold", "Cast when HP is below this percent (0.0 - 1.0)", 2)
            menu_elements.cast_on_cooldown:render("Cast on Cooldown", "Always cast when ready (maintains buff constantly)")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
            menu_elements.is_independent:render("Independent Cast", "Cast independently of the rotation priority")
=======
            -- Logic
            menu_elements.cast_on_cooldown:render("Cast on Cooldown",
                "Always cast when ready (maintains buff constantly)")

            -- Cast Settings
            menu_elements.cast_delay:render("Cast Delay", "Time to wait after casting before taking another action",
                2)
>>>>>>> Stashed changes
>>>>>>> Stashed changes
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.rally.spell_id);

    if not is_logic_allowed then return false end;

    -- Check cast on cooldown option
    if menu_elements.cast_on_cooldown:get() then
        -- Cast immediately when ready with minimal delay to maintain buff
        if cast_spell.self(spell_data.rally.spell_id, 0) then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + 0.1; -- Small delay to prevent spam
            console.print("Cast Rally (On Cooldown)");
            return true, 0.1;
        end;
        return false;
    end

    -- Original logic for situational casting
    local current_time = get_time_since_inject()
    local last_cast = my_utility.get_last_cast_time("rally")

    -- Don't cast if we cast it less than 6 seconds ago (Duration is 8s)
    if current_time < last_cast + 6.0 then
        return false
    end

    if cast_spell.self(spell_data.rally.spell_id, 0) then
        local cast_delay = menu_elements.cast_delay:get();
        next_time_allowed_cast = current_time + cast_delay;
        console.print("Cast Rally");
        return true, cast_delay;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
