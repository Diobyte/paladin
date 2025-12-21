---@diagnostic disable: undefined-global, undefined-field
local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local max_spell_range = 15.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "falling_star_main_bool_base")),
    targeting_mode      = my_utility.safe_combo_box(0, get_hash(my_utility.plugin_label .. "falling_star_targeting_mode")),

    advanced_tree       = my_utility.safe_tree_tab(2),
    priority_target     = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "falling_star_priority_target")),
    min_target_range    = my_utility.safe_slider_float(1, max_spell_range - 1, 3,
        get_hash(my_utility.plugin_label .. "falling_star_min_target_range")),
    recast_delay        = my_utility.safe_slider_float(0.0, 10.0, 0.5,
        get_hash(my_utility.plugin_label .. "falling_star_recast_delay")),
    elites_only         = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "falling_star_elites_only")),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "falling_star_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 5.0, 0.1,
        get_hash(my_utility.plugin_label .. "falling_star_custom_cooldown_sec")),
    cast_delay          = my_utility.safe_slider_float(0.01, 1.0, 0.1,
        get_hash(my_utility.plugin_label .. "falling_star_cast_delay")),
    debug_mode          = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "falling_star_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Falling Star") then
        menu_elements.main_boolean:render("Enable Falling Star", "")
        if menu_elements.main_boolean:get() then
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)

            if menu_elements.advanced_tree:push("Advanced Settings") then
                menu_elements.priority_target:render("Priority Targeting (Ignore weighted targeting)",
                    "Targets Boss > Champion > Elite > Any")
                menu_elements.min_target_range:render("Min Target Distance",
                    "\n     Must be lower than Max Targeting Range     \n\n", 1)
                menu_elements.recast_delay:render("Recast Delay (Melee)",
                    "\n     Minimum time between casts when in melee range (prevents spamming on bosses)     \n\n", 1)
                menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
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

local function logics(target, target_selector_data)
    if not target then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[FALLING STAR DEBUG] No target provided")
        end
        return false
    end;

    -- Handle priority targeting mode
    if menu_elements.priority_target:get() and target_selector_data then
        local priority_target = my_target_selector.get_priority_target(target_selector_data)
        if priority_target and my_utility.is_in_range(priority_target, max_spell_range) then
            target = priority_target
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[FALLING STAR DEBUG] Priority targeting enabled - using priority target: " ..
                    (target:get_skin_name() or "Unknown"))
            end
        else
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[FALLING STAR DEBUG] No valid priority target in range, using original target")
            end
        end
    end

    if menu_elements.elites_only:get() and not target:is_elite() then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[FALLING STAR DEBUG] Elites only mode - target is not elite")
        end
        return false
    end

    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.falling_star.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[FALLING STAR DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    if not my_utility.is_in_range(target, max_spell_range) then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[FALLING STAR DEBUG] Target out of range")
        end
        return false
    end

    -- Logic:
    -- 1. If outside min_range (Gap Close): Cast immediately.
    -- 2. If inside min_range (Boss DPS): Cast only if recast_delay has passed.
    local is_in_min_range = my_utility.is_in_range(target, menu_elements.min_target_range:get())

    if is_in_min_range then
        -- We are in melee range (Boss logic)
        if not target:is_boss() then
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[FALLING STAR DEBUG] In melee range but target is not boss")
            end
            return false
        end

        local current_time = get_time_since_inject()
        local last_cast = my_utility.get_last_cast_time("falling_star")
        if current_time < last_cast + menu_elements.recast_delay:get() then
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[FALLING STAR DEBUG] Recast delay not met for boss DPS")
            end
            return false
        end
    end

    local cast_ok, delay = my_utility.try_cast_spell("falling_star", spell_data.falling_star.spell_id, menu_boolean,
        next_time_allowed_cast, function()
            return cast_spell.position(spell_data.falling_star.spell_id, target:get_position(), 0)
        end, menu_elements.cast_delay:get())

    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or
            (delay or menu_elements.cast_delay:get());
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Falling Star - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
        -- Return the cast delay (animation time) instead of the full cooldown so other spells can be cast
        return true, delay or menu_elements.cast_delay:get();
    end;

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[FALLING STAR DEBUG] Cast failed")
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
