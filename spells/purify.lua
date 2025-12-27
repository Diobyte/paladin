---@diagnostic disable: undefined-global, undefined-field
local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0 -- Self-cast
local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true, get_hash(my_utility.plugin_label .. "purify_main_bool_base")),

    advanced_tree       = my_utility.safe_tree_tab(2),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "purify_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "purify_custom_cooldown_sec")),
    debug_mode          = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "purify_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Purify") then
        menu_elements.main_boolean:render("Enable Purify", "Cleansing ultimate that removes debuffs and heals")

        if menu_elements.main_boolean:get() then
            if menu_elements.advanced_tree:push("Advanced Settings") then
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
    -- Purify is a self-cast cleansing/healing skill - doesn't need a target
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_data.purify
        .spell_id);
    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[PURIFY DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    local cast_ok, delay = my_utility.try_cast_spell("purify", spell_data.purify.spell_id, menu_boolean,
        next_time_allowed_cast, function()
            return cast_spell.self(spell_data.purify.spell_id, spell_data.purify.cast_delay)
        end, spell_data.purify.cast_delay)
    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or
            (delay or spell_data.purify.cast_delay);
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Purify - Cleansing Activated");
        return true, cooldown;
    end

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[PURIFY DEBUG] Cast failed")
    end
    return false;
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    set_next_time_allowed_cast = function(t) next_time_allowed_cast = t end
}
