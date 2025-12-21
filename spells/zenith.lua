local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements =
{
    tree_tab     = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash(my_utility.plugin_label .. "zenith_main_bool_base")),
    cast_delay   = slider_float:new(0.01, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "zenith_cast_delay")),
    debug_mode   = my_utility.safe_checkbox(false, get_hash(my_utility.plugin_label .. "zenith_debug_mode")),
}

local function menu()
    if menu_elements.tree_tab:push("Zenith") then
        menu_elements.main_boolean:render("Enable Zenith", "")
        menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
        menu_elements.debug_mode:render("Debug Mode", "Enable debug logging for troubleshooting")

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.zenith.spell_id);

    if not is_logic_allowed then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ZENITH DEBUG] Logic not allowed - spell conditions not met")
        end
        return false
    end;

    -- Check Faith cost
    local local_player = get_local_player();
    local current_faith = local_player:get_primary_resource_current();
    if current_faith < spell_data.zenith.faith_cost then
        if menu_elements.debug_mode:get() then
            my_utility.debug_print("[ZENITH DEBUG] Not enough Faith - required: " ..
            spell_data.zenith.faith_cost .. ", current: " .. current_faith)
        end
        return false
    end

    -- Use helper to perform the cast and record
    local cast_ok, delay = my_utility.try_cast_spell("zenith", spell_data.zenith.spell_id, menu_boolean,
        next_time_allowed_cast, function()
            return cast_spell.self(spell_data.zenith.spell_id, 0)
        end, menu_elements.cast_delay:get())

    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = (delay or menu_elements.cast_delay:get());
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Zenith");
        return true, cooldown;
    end;

    if menu_elements.debug_mode:get() then
        my_utility.debug_print("[ZENITH DEBUG] Cast failed")
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
