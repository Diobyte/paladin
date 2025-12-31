---@diagnostic disable: undefined-global, undefined-field
local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true, get_hash(my_utility.plugin_label .. "rally_main_bool_base")),

    advanced_tree       = my_utility.safe_tree_tab(2),
    use_for_faith       = my_utility.safe_checkbox(true, get_hash(my_utility.plugin_label .. "rally_use_for_faith")),
    min_faith_pct       = my_utility.safe_slider_float(0.1, 0.9, 0.5,
        get_hash(my_utility.plugin_label .. "rally_min_faith_pct")),
    cast_on_cooldown    = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "rally_cast_on_cooldown")),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "rally_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "rally_custom_cooldown_sec")),
    debug_mode          = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "rally_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Rally") then
        menu_elements.main_boolean:render("Enable Rally", "")
        if menu_elements.main_boolean:get() then
            if menu_elements.advanced_tree:push("Advanced Settings") then
                menu_elements.use_for_faith:render("Use for Faith Generation",
                    "Cast Rally when Faith is low to generate resources")
                if menu_elements.use_for_faith:get() then
                    menu_elements.min_faith_pct:render("Min Faith %", "Cast when Faith is below this percentage", 1)
                end
                menu_elements.cast_on_cooldown:render("Cast on Cooldown",
                    "Always cast when ready (maintains buff constantly)")
                menu_elements.use_custom_cooldown:render("Use Custom Cooldown",
                    "Override the default cooldown with a custom value")
                if menu_elements.use_custom_cooldown:get() then
                    menu_elements.custom_cooldown_sec:render("Custom Cooldown (sec)",
                        "Set the custom cooldown in seconds", 2)
                end
                menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
                menu_elements.advanced_tree:pop()
            end
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

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[RALLY DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    -- Check cast on cooldown option via helper
    local maintained, mdelay = my_utility.try_maintain_buff("rally", spell_data.rally.spell_id, menu_elements)
    if maintained ~= nil then
        if maintained then
            local current_time = get_time_since_inject();
            local cd = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or mdelay
            next_time_allowed_cast = current_time + cd;
            my_utility.debug_print("Cast Rally (On Cooldown)");
            return true, cd;
        end
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[RALLY DEBUG] Cast on cooldown failed")
        end
        return false
    end

    -- Faith Generation Logic
    if menu_elements.use_for_faith:get() then
        local local_player = get_local_player()
        local current_faith_pct = local_player:get_primary_resource_current() / local_player:get_primary_resource_max()
        if current_faith_pct < menu_elements.min_faith_pct:get() then
            local cast_ok, delay = my_utility.try_cast_spell("rally", spell_data.rally.spell_id, menu_boolean,
                next_time_allowed_cast,
                function() return cast_spell.self(spell_data.rally.spell_id, spell_data.rally.cast_delay) end,
                spell_data.rally.cast_delay)

            if cast_ok then
                local cooldown = (delay or spell_data.rally.cast_delay);
                if menu_elements.use_custom_cooldown:get() then
                    cooldown = menu_elements.custom_cooldown_sec:get()
                end
                my_utility.debug_print("Cast Rally (Faith Gen)");
                return true, cooldown;
            end
        end
    end

    -- Original logic for situational casting
    local current_time = get_time_since_inject()
    local last_cast = my_utility.get_last_cast_time("rally")

    -- Don't cast if we cast it less than 6 seconds ago (Duration is 8s)
    if current_time < last_cast + 6.0 then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[RALLY DEBUG] Too soon since last cast")
        end
        return false
    end

    local cast_ok, delay = my_utility.try_cast_spell("rally", spell_data.rally.spell_id, menu_boolean,
        next_time_allowed_cast,
        function() return cast_spell.self(spell_data.rally.spell_id, spell_data.rally.cast_delay) end,
        spell_data.rally.cast_delay)

    if cast_ok then
        local cooldown = (delay or spell_data.rally.cast_delay);

        if menu_elements.use_custom_cooldown:get() then
            cooldown = menu_elements.custom_cooldown_sec:get()
        end

        my_utility.debug_print("Cast Rally");
        return true, cooldown;
    end;

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[RALLY DEBUG] Cast failed")
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
