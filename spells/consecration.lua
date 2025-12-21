---@diagnostic disable: undefined-global, undefined-field
local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "consecration_main_bool_base")),

    advanced_tree       = my_utility.safe_tree_tab(2),
    cast_on_cooldown    = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "consecration_cast_on_cooldown")),
    cast_delay          = my_utility.safe_slider_float(0.01, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "consecration_cast_delay")),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "consecration_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 5.0, 0.1,
        get_hash(my_utility.plugin_label .. "consecration_custom_cooldown_sec")),
    debug_mode          = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "consecration_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Consecration") then
        menu_elements.main_boolean:render("Enable Consecration", "")
        if menu_elements.main_boolean:get() then
            if menu_elements.advanced_tree:push("Advanced Settings") then
                menu_elements.cast_on_cooldown:render("Cast on Cooldown",
                    "Always cast when ready (maintains buff constantly)")
                menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
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
        spell_data.consecration.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[CONSECRATION DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    -- Check cast on cooldown option via helper
    local maintained, mdelay = my_utility.try_maintain_buff("consecration", spell_data.consecration.spell_id,
        menu_elements)
    if maintained ~= nil then
        -- cast_on_cooldown is enabled; if we successfully cast, set delay and return
        if maintained then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + mdelay;
            my_utility.debug_print("Cast Consecration (On Cooldown)");
            if menu_elements.use_custom_cooldown:get() then
                return true, menu_elements.custom_cooldown_sec:get()
            end
            return true, mdelay;
        end
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[CONSECRATION DEBUG] Cast on cooldown failed")
        end
        return false
    end

    local cast_ok, delay = my_utility.try_cast_spell("consecration", spell_data.consecration.spell_id, menu_boolean,
        next_time_allowed_cast,
        function() return cast_spell.self(spell_data.consecration.spell_id, 0) end, menu_elements.cast_delay:get())
    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = (delay or menu_elements.cast_delay:get());
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Consecration");
        if menu_elements.use_custom_cooldown:get() then
            return true, menu_elements.custom_cooldown_sec:get()
        end
        return true, cooldown;
    end;

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[CONSECRATION DEBUG] Cast failed")
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
