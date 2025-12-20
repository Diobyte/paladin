local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(true, get_hash(my_utility.plugin_label .. "rally_main_bool_base")),
    hp_threshold     = slider_float:new(0.0, 1.0, 0.5, get_hash(my_utility.plugin_label .. "rally_hp_threshold")),
    min_faith        = slider_float:new(0.0, 1.0, 0.5, get_hash(my_utility.plugin_label .. "rally_min_faith")),
    move_speed_mode  = checkbox:new(false, get_hash(my_utility.plugin_label .. "rally_move_speed_mode")),
    cast_on_cooldown = checkbox:new(false, get_hash(my_utility.plugin_label .. "rally_cast_on_cooldown")),
    force_priority   = checkbox:new(true, get_hash(my_utility.plugin_label .. "rally_force_priority")),
}

local function menu()
    if menu_elements.tree_tab:push("Rally") then
        menu_elements.main_boolean:render("Enable Spell", "Enable or disable this spell")

        if menu_elements.main_boolean:get() then
            menu_elements.hp_threshold:render("HP Threshold", "Cast when HP is below this percent (0.0 - 1.0)", 2)
            menu_elements.min_faith:render("Min Faith %", "Cast when Faith is below this % to generate Faith", 2)
            menu_elements.move_speed_mode:render("Move Speed Mode", "Cast when moving to gain speed boost")

            -- Logic
            menu_elements.cast_on_cooldown:render("Cast on Cooldown",
                "Always cast when ready (maintains buff constantly)")
            menu_elements.force_priority:render("Force Priority", "Always cast on Boss/Elite/Champion (if applicable)")
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

    local local_player = get_local_player()
    local current_faith_pct = local_player:get_primary_resource_current() / local_player:get_primary_resource_max()
    local min_faith = menu_elements.min_faith:get()

    if current_faith_pct <= min_faith then
        if cast_spell.self(spell_data.rally.spell_id, 0) then
            local cast_delay = 0.1;
            next_time_allowed_cast = current_time + cast_delay;
            console.print("Cast Rally (Faith Gen)");
            return true, cast_delay;
        end
    end

    if menu_elements.move_speed_mode:get() and local_player:is_moving() then
        if cast_spell.self(spell_data.rally.spell_id, 0) then
            local cast_delay = 0.1;
            next_time_allowed_cast = current_time + cast_delay;
            console.print("Cast Rally (Speed)");
            return true, cast_delay;
        end
    end

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}
