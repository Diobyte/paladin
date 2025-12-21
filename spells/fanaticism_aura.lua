local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0
local menu_elements =
{
    tree_tab         = my_utility.safe_tree_tab(1),
    main_boolean     = my_utility.safe_checkbox(true,
        get_hash(my_utility.plugin_label .. "fanaticism_aura_main_bool_base")),
    cast_on_cooldown = my_utility.safe_checkbox(false,
        get_hash(my_utility.plugin_label .. "fanaticism_aura_cast_on_cooldown")),
    cast_delay       = my_utility.safe_slider_float(0.01, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "fanaticism_aura_cast_delay")),
}

local function menu()
    if menu_elements.tree_tab:push("Fanaticism Aura") then
        menu_elements.main_boolean:render("Enable Fanaticism Aura", "")
        if menu_elements.main_boolean:get() then
            menu_elements.cast_on_cooldown:render("Cast on Cooldown",
                "Always cast when ready (maintains buff constantly)")
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
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
        spell_data.fanaticism_aura.spell_id);

    if not is_logic_allowed then return false end;

    -- Check cast on cooldown option via helper
    local maintained, mdelay = my_utility.try_maintain_buff("fanaticism_aura", spell_data.fanaticism_aura.spell_id,
        menu_elements)
    if maintained ~= nil then
        if maintained then
            local current_time = get_time_since_inject();
            next_time_allowed_cast = current_time + mdelay;
            my_utility.debug_print("Cast Fanaticism Aura (On Cooldown)");
            return true, mdelay;
        end
        return false
    end

    local cast_ok, delay = my_utility.try_cast_spell("fanaticism_aura", spell_data.fanaticism_aura.spell_id, menu_boolean,
        next_time_allowed_cast,
        function() return cast_spell.self(spell_data.fanaticism_aura.spell_id, 0) end, menu_elements.cast_delay:get())
    if cast_ok then
        local current_time = get_time_since_inject();
        local cooldown = (delay or menu_elements.cast_delay:get());
        next_time_allowed_cast = current_time + cooldown;
        my_utility.debug_print("Cast Fanaticism Aura");
        return true, cooldown;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    set_next_time_allowed_cast = function(t) next_time_allowed_cast = t end
}
