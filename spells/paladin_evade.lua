---@diagnostic disable: undefined-global, undefined-field
local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 10.0
local targeting_type = "both"
local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "paladin_evade_main_bool_base")),
    targeting_mode      = my_utility.safe_combo_box(0,
        get_hash(my_utility.plugin_label .. "paladin_evade_targeting_mode")),

    advanced_tree       = my_utility.safe_tree_tab(2),
    min_target_range    = my_utility.safe_slider_float(3, max_spell_range - 1, 5,
        get_hash(my_utility.plugin_label .. "paladin_evade_min_target_range")),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "paladin_evade_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 5.0, 0.1,
        get_hash(my_utility.plugin_label .. "paladin_evade_custom_cooldown_sec")),
    cast_delay          = my_utility.safe_slider_float(0.01, 1.0, 0.1,
        get_hash(my_utility.plugin_label .. "paladin_evade_cast_delay")),
    debug_mode          = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "paladin_evade_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Paladin Evade") then
        menu_elements.main_boolean:render("Enable Paladin Evade", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes,
                my_utility.targeting_mode_description)

            if menu_elements.advanced_tree:push("Advanced Settings") then
                menu_elements.min_target_range:render("Min Target Distance",
                    "\n     Must be lower than Max Targeting Range     \n\n", 1)
                menu_elements.use_custom_cooldown:render("Use Custom Cooldown",
                    "Override the default cooldown with a custom value")
                if menu_elements.use_custom_cooldown:get() then
                    menu_elements.custom_cooldown_sec:render("Custom Cooldown (sec)",
                        "Set the custom cooldown in seconds", 2)
                end
                menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
                menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
                menu_elements.advanced_tree:pop()
            end
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    if not target then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[PALADIN EVADE DEBUG] No target provided")
        end
        return false
    end;

    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.paladin_evade.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[PALADIN EVADE DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    if not my_utility.is_in_range(target, max_spell_range) or my_utility.is_in_range(target, menu_elements.min_target_range:get()) then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[PALADIN EVADE DEBUG] Target not in valid range")
        end
        return false
    end

    local cast_ok, delay = my_utility.try_cast_spell("paladin_evade", spell_data.paladin_evade.spell_id, menu_boolean,
        next_time_allowed_cast,
        function() return cast_spell.position(spell_data.paladin_evade.spell_id, target:get_position(), 0) end,
        menu_elements.cast_delay:get())
    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or
            (delay or menu_elements.cast_delay:get());
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Paladin Evade");
        return true, cooldown;
    end;

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[PALADIN EVADE DEBUG] Cast failed")
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
