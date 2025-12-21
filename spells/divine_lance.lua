local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 15.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "divine_lance_main_bool_base")),
    targeting_mode      = my_utility.safe_combo_box(0, get_hash(my_utility.plugin_label .. "divine_lance_targeting_mode")),
    priority_target     = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "divine_lance_priority_target")),
    min_target_range    = my_utility.safe_slider_float(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "divine_lance_min_target_range")),
    elites_only         = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "divine_lance_elites_only")),
    cast_delay          = my_utility.safe_slider_float(0.01, 1.0, 0.1,
        get_hash(my_utility.plugin_label .. "divine_lance_cast_delay")),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "divine_lance_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 5.0, 0.1,
        get_hash(my_utility.plugin_label .. "divine_lance_custom_cooldown_sec")),
    debug_mode          = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "divine_lance_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Divine Lance") then
        menu_elements.main_boolean:render("Enable Divine Lance", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.priority_target:render("Priority Targeting (Ignore weighted targeting)",
                "Targets Boss > Champion > Elite > Any")
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
            menu_elements.use_custom_cooldown:render("Use Custom Cooldown",
                "Override the default cooldown with a custom value")
            if menu_elements.use_custom_cooldown:get() then
                menu_elements.custom_cooldown_sec:render("Custom Cooldown (sec)", "Set the custom cooldown in seconds", 2)
            end
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target, target_selector_data)
    -- Priority Targeting Mode: prioritize targets by type
    if menu_elements.priority_target:get() and target_selector_data then
        local my_target_selector = require("my_utility/my_target_selector")
        local priority_best_target, target_type = my_target_selector.get_priority_target(target_selector_data)

        if menu_elements.debug_mode:get() then
            console.print("[DIVINE LANCE DEBUG] Priority targeting mode - Target type: " .. target_type)
        end

        if priority_best_target then
            target = priority_best_target
        else
            if menu_elements.debug_mode:get() then
                console.print("[DIVINE LANCE DEBUG] No priority target found")
            end
            return false
        end
        -- Regular target mode (using the target passed from main.lua)
    else
        if menu_elements.debug_mode:get() then
            console.print("[DIVINE LANCE DEBUG] Regular target mode")
        end
        if not target then
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[DIVINE LANCE DEBUG] No target provided")
            end
            return false
        end
    end

    if menu_elements.elites_only:get() and not target:is_elite() then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[DIVINE LANCE DEBUG] Elites only mode - target is not elite")
        end
        return false
    end

    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.divine_lance.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[DIVINE LANCE DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[DIVINE LANCE DEBUG] Target not in valid range")
        end
        return false
    end

    local cast_ok, delay = my_utility.try_cast_spell("divine_lance", spell_data.divine_lance.spell_id, menu_boolean,
        next_time_allowed_cast,
        function() return cast_spell.target(target, spell_data.divine_lance.spell_id, 0, false) end,
        menu_elements.cast_delay:get())
    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = (delay or menu_elements.cast_delay:get());
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Divine Lance - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
        if menu_elements.use_custom_cooldown:get() then
            return true, menu_elements.custom_cooldown_sec:get()
        end
        return true, cooldown;
    end;

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[DIVINE LANCE DEBUG] Cast failed")
    end
    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type,
    set_next_time_allowed_cast = function(t) next_time_allowed_cast = t end
}
