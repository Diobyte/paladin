local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local max_spell_range = 10.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true, get_hash(my_utility.plugin_label .. "advance_main_bool_base")),
    targeting_mode      = my_utility.safe_combo_box(0, get_hash(my_utility.plugin_label .. "advance_targeting_mode")),
    priority_target     = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "advance_priority_target")),
    mobility_only       = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "advance_mobility_only")),
    min_target_range    = my_utility.safe_slider_float(0.0, max_spell_range - 1, 0.0,
        get_hash(my_utility.plugin_label .. "advance_min_target_range")),
    max_faith           = my_utility.safe_slider_float(0.1, 1.0, 0.9,
        get_hash(my_utility.plugin_label .. "advance_max_faith")),
    force_priority      = my_utility.safe_checkbox(true, get_hash(my_utility.plugin_label .. "advance_force_priority")),
    elites_only         = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "advance_elites_only")),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "advance_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 5.0, 1.0,
        get_hash(my_utility.plugin_label .. "advance_custom_cooldown_sec")),
    cast_delay          = my_utility.safe_slider_float(0.01, 1.0, 0.1,
        get_hash(my_utility.plugin_label .. "advance_cast_delay")),
    debug_mode          = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "advance_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Advance") then
        menu_elements.main_boolean:render("Enable Spell", "Enable or disable this spell")

        if menu_elements.main_boolean:get() then
            -- Targeting
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.priority_target:render("Priority Targeting (Ignore weighted targeting)",
                "Targets Boss > Champion > Elite > Any")
            menu_elements.min_target_range:render("Min Target Range", "Minimum distance to target to allow casting", 1)

            -- Logic
            menu_elements.max_faith:render("Max Faith %", "Don't cast if Faith is above this % (unless Mobility Only)", 1)
            menu_elements.mobility_only:render("Mobility Only", "Only use this spell for gap closing/mobility")
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite/Boss enemies")
            menu_elements.use_custom_cooldown:render("Use Custom Cooldown", "")
            if menu_elements.use_custom_cooldown:get() then
                menu_elements.custom_cooldown_sec:render("Custom Cooldown (sec)", "Override default cast delay")
            end
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
        end

        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target, target_selector_data)
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.advance.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ADVANCE DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    local mobility_only = menu_elements.mobility_only:get();

    -- Handle priority targeting mode for combat mode
    if menu_elements.priority_target:get() and target_selector_data and not mobility_only then
        local priority_target = my_target_selector.get_priority_target(target_selector_data)
        if priority_target and my_utility.is_in_range(priority_target, max_spell_range) then
            target = priority_target
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[ADVANCE DEBUG] Priority targeting enabled - using priority target: " ..
                    (target:get_skin_name() or "Unknown"))
            end
        else
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[ADVANCE DEBUG] No valid priority target in range, using original target")
            end
        end
    end

    -- Check if we have a valid target based on targeting mode
    if not target then
        -- No target found with current targeting mode
        if not mobility_only then
            if menu_elements.debug_mode:get() then
                my_utility.debug_print("[ADVANCE DEBUG] No target and not in mobility mode")
            end
            return false -- Can't cast without a target in combat mode
        end
    end

    if target and menu_elements.elites_only:get() and not target:is_elite() then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ADVANCE DEBUG] Elites only mode - target is not elite")
        end
        return false
    end

    local cast_position = nil
    local force_priority = menu_elements.force_priority:get()
    local is_priority = target and my_utility.is_high_priority_target(target)

    if mobility_only then
        if target then
            if not my_utility.is_in_range(target, max_spell_range) then return false end

            local is_in_min_range = my_utility.is_in_range(target, menu_elements.min_target_range:get())
            if is_in_min_range and not (force_priority and is_priority) then
                return false
            end
            cast_position = target:get_position()
        else
            -- For mobility without target, cast towards cursor
            local cursor_position = get_cursor_position()
            local player_position = get_player_position()
            if cursor_position:squared_dist_to_ignore_z(player_position) > max_spell_range * max_spell_range then
                return false -- Cursor too far
            end
            cast_position = cursor_position
        end
    else
        -- Combat mode: require target
        if not target then return false end

        if not my_utility.is_in_range(target, max_spell_range) then return false end

        local local_player = get_local_player()
        local current_faith_pct = local_player:get_primary_resource_current() / local_player:get_primary_resource_max()
        local max_faith = menu_elements.max_faith:get()

        if current_faith_pct > max_faith and not (force_priority and is_priority) then
            return false
        end

        local is_in_min_range = my_utility.is_in_range(target, menu_elements.min_target_range:get())
        if is_in_min_range and not (force_priority and is_priority) then
            return false
        end
        cast_position = target:get_position()
    end

    local cast_ok, delay = my_utility.try_cast_spell("advance", spell_data.advance.spell_id, menu_boolean,
        next_time_allowed_cast, function()
            return cast_spell.position(spell_data.advance.spell_id, cast_position, 0)
        end, menu_elements.cast_delay:get())
    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or
            (delay or menu_elements.cast_delay:get());
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Advance - Target: " ..
            (target and my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1] or "None") ..
            ", Mobility: " .. tostring(mobility_only));
        return true, cooldown
    end

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[ADVANCE DEBUG] Cast failed")
    end
    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    set_next_time_allowed_cast = function(t) next_time_allowed_cast = t end
}
