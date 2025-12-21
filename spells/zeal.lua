local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 5.0
local targeting_type = "melee"
local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true, get_hash(my_utility.plugin_label .. "zeal_main_bool_base")),
    targeting_mode      = my_utility.safe_combo_box(0, get_hash(my_utility.plugin_label .. "zeal_targeting_mode")),
    priority_target     = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "zeal_priority_target")),
    min_target_range    = my_utility.safe_slider_float(0, max_spell_range - 1, 0,
        get_hash(my_utility.plugin_label .. "zeal_min_target_range")),
    elites_only         = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "zeal_elites_only")),
    use_custom_cooldown = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "zeal_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 5.0, 1.0,
        get_hash(my_utility.plugin_label .. "zeal_custom_cooldown_sec")),
    cast_delay          = my_utility.safe_slider_float(0.01, 1.0, 0.1,
        get_hash(my_utility.plugin_label .. "zeal_cast_delay")),
    debug_mode          = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "zeal_debug_mode")),
}

local zeal_data = spell_data.zeal.data

local function menu()
    if menu_elements.tree_tab:push("Zeal") then
        menu_elements.main_boolean:render("Enable Zeal", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_melee,
                my_utility.targeting_mode_description)
            menu_elements.priority_target:render("Priority Targeting (Ignore weighted targeting)",
                "Targets Boss > Champion > Elite > Any")
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
            menu_elements.use_custom_cooldown:render("Use Custom Cooldown", "")
            if menu_elements.use_custom_cooldown:get() then
                menu_elements.custom_cooldown_sec:render("Custom Cooldown (sec)", "Override default cast delay")
            end
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target, target_selector_data)
    if not target then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ZEAL DEBUG] No target provided")
        end
        return false
    end;

    -- Handle priority targeting mode
    if menu_elements.priority_target:get() and target_selector_data then
        local priority_target = target_selector_data.get_priority_target()
        if priority_target then
            target = priority_target
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[ZEAL DEBUG] Priority targeting enabled - using priority target: " ..
                    (target:get_skin_name() or "Unknown"))
            end
        else
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[ZEAL DEBUG] Priority targeting enabled but no priority target found")
            end
            return false
        end
    end

    if menu_elements.elites_only:get() and not target:is_elite() then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ZEAL DEBUG] Elites only mode - target is not elite")
        end
        return false
    end

    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.zeal.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ZEAL DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    -- Check Faith cost
    local local_player = get_local_player();
    local current_faith = local_player:get_primary_resource_current();
    if current_faith < spell_data.zeal.faith_cost then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ZEAL DEBUG] Not enough Faith - required: " ..
                spell_data.zeal.faith_cost .. ", current: " .. current_faith)
        end
        return false
    end

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ZEAL DEBUG] Target not in valid range")
        end
        return false
    end

    local cast_ok = cast_spell.target(target, spell_data.zeal.spell_id, 0, false)
    if cast_ok then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + my_utility.spell_delays.regular_cast;
        console.print("Cast Zeal - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
        return true, my_utility.spell_delays.regular_cast
    end

    if menu_elements.debug_mode:get() then
        console.print("[ZEAL DEBUG] Cast failed")
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
