---@diagnostic disable: undefined-global, undefined-field
local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 15.0
local menu_elements =
{
    tree_tab            = my_utility.safe_tree_tab(1),
    main_boolean        = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "holy_light_aura_main_bool_base")),
    cast_on_cooldown    = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "holy_light_aura_cast_on_cooldown")),
    use_custom_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "holy_light_aura_use_custom_cooldown")),
    custom_cooldown_sec = my_utility.safe_slider_float(0.1, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "holy_light_aura_custom_cooldown_sec")),
    max_cast_range      = my_utility.safe_slider_float(1.0, 15.0, 5.0,
        get_hash(my_utility.plugin_label .. "holy_light_aura_max_cast_range")),
    cast_delay          = my_utility.safe_slider_float(0.01, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "holy_light_aura_cast_delay")),
    debug_mode          = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "holy_light_aura_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Holy Light Aura") then
        menu_elements.main_boolean:render("Enable Holy Light Aura", "")
        if menu_elements.main_boolean:get() then
            menu_elements.cast_on_cooldown:render("Cast on Cooldown",
                "Always cast when ready (maintains buff constantly)")
            menu_elements.use_custom_cooldown:render("Use Custom Cooldown",
                "Override the default cooldown with a custom value")
            if menu_elements.use_custom_cooldown:get() then
                menu_elements.custom_cooldown_sec:render("Custom Cooldown (sec)",
                    "Set the custom cooldown in seconds", 2)
            end
            menu_elements.max_cast_range:render("Max Cast Range", "Only cast when enemies are within this range", 1)
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
            menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")
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
        spell_data.holy_light_aura.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[HOLY LIGHT AURA DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    -- Check if there are enemies within the specified range
    local enemy_count = my_utility.enemy_count_simple(menu_elements.max_cast_range:get());
    if enemy_count == 0 then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[HOLY LIGHT AURA DEBUG] No enemies within range")
        end
        return false
    end;

    -- Check cast on cooldown option via helper
    local maintained, mdelay = my_utility.try_maintain_buff("holy_light_aura", spell_data.holy_light_aura.spell_id,
        menu_elements)
    if maintained ~= nil then
        if maintained then
            local current_time = get_time_since_inject();
            local cd = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or mdelay
            next_time_allowed_cast = current_time + cd;
            my_utility.debug_print("Cast Holy Light Aura (On Cooldown)");
            return true, cd;
        end
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[HOLY LIGHT AURA DEBUG] Cast on cooldown failed")
        end
        return false
    end

    local cast_ok, delay = my_utility.try_cast_spell("holy_light_aura", spell_data.holy_light_aura.spell_id, menu_boolean,
        next_time_allowed_cast,
        function() return cast_spell.self(spell_data.holy_light_aura.spell_id, 0) end, menu_elements.cast_delay:get())
    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = menu_elements.use_custom_cooldown:get() and menu_elements.custom_cooldown_sec:get() or
            (delay or menu_elements.cast_delay:get());
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Holy Light Aura");
        return true, cooldown;
    end;

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[HOLY LIGHT AURA DEBUG] Cast failed")
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
