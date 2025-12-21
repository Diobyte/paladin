local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 5.0
local targeting_type = "melee"
local menu_elements =
{
    tree_tab           = my_utility.safe_tree_tab(1),
    main_boolean       = my_utility.safe_checkbox(true, get_hash(my_utility.plugin_label .. "clash_main_bool_base")),
    targeting_mode     = my_utility.safe_combo_box(0, get_hash(my_utility.plugin_label .. "clash_targeting_mode")),
    min_target_range   = my_utility.safe_slider_float(0, max_spell_range - 1, 0,
        get_hash(my_utility.plugin_label .. "clash_min_target_range")),
    elites_only        = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "clash_elites_only")),
    cast_delay         = my_utility.safe_slider_float(0.01, 1.0, 0.1,
        get_hash(my_utility.plugin_label .. "clash_cast_delay")),
    debug_mode         = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "clash_debug_mode")),
    use_as_filler_only = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "clash_use_as_filler_only")),
    max_faith          = my_utility.safe_slider_int(1, 100, 35,
        get_hash(my_utility.plugin_label .. "clash_max_faith")),
}

local function menu()
    if menu_elements.tree_tab:push("Clash") then
        menu_elements.main_boolean:render("Enable Clash", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_melee,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Distance",
                "\n     Must be lower than Max Targeting Range     \n\n", 1)
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
            menu_elements.use_as_filler_only:render("Filler Only", "Prevent casting with high Faith")
            if menu_elements.use_as_filler_only:get() then
                menu_elements.max_faith:render("Max Faith", "Prevent casting with more Faith than this value")
            end
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    if not target then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[CLASH DEBUG] No target provided")
        end
        return false
    end;

    if menu_elements.elites_only:get() and not target:is_elite() then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[CLASH DEBUG] Elites only mode - target is not elite")
        end
        return false
    end

    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.clash.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[CLASH DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    -- Precondition: requires a shield to be equipped
    if spell_data.clash.requires_shield and not my_utility.has_shield() then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[CLASH DEBUG] Requires shield but no shield equipped")
        end
        return false
    end;

    -- Filler logic: only cast when low on Faith
    local is_filler_enabled = menu_elements.use_as_filler_only:get();
    if is_filler_enabled then
        local player_local = get_local_player();
        local current_resource_faith = player_local:get_primary_resource_current();
        local max_faith = menu_elements.max_faith:get();
        local low_in_faith = current_resource_faith < max_faith;

        if not low_in_faith then
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[CLASH DEBUG] Filler mode - Faith too high: " ..
                current_resource_faith .. "/" .. max_faith)
            end
            return false;
        end
    end;

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[CLASH DEBUG] Target not in valid range")
        end
        return false
    end

    local cast_ok, delay = my_utility.try_cast_spell("clash", spell_data.clash.spell_id, menu_boolean,
        next_time_allowed_cast, function()
            return cast_spell.target(target, spell_data.clash.spell_id, 0, false)
        end, menu_elements.cast_delay:get())
    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = (delay or menu_elements.cast_delay:get());
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Clash - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
        return true, cooldown
    end

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[CLASH DEBUG] Cast failed")
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
