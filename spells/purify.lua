local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local max_spell_range = 0.0  -- Self-cast
local menu_elements =
{
    tree_tab            = tree_node:new(1),
    main_boolean        = checkbox:new(true, get_hash(my_utility.plugin_label .. "purify_main_bool_base")),
    hp_threshold        = slider_float:new(0.0, 1.0, 0.6, get_hash(my_utility.plugin_label .. "purify_hp_threshold")),
    cast_delay          = slider_float:new(0.01, 10.0, 0.1,
        get_hash(my_utility.plugin_label .. "purify_cast_delay")),
    is_independent      = checkbox:new(false, get_hash(my_utility.plugin_label .. "purify_is_independent")),
}

local function menu()
    if menu_elements.tree_tab:push("Purify") then
        menu_elements.main_boolean:render("Enable Purify", "Cleansing ultimate that removes debuffs and heals")
        if menu_elements.main_boolean:get() then
            menu_elements.hp_threshold:render("HP Threshold", "Cast when HP is below this percent (0.0 - 1.0)", 2)
            menu_elements.cast_delay:render("Cast Delay", "Time between casts in seconds", 2)
            menu_elements.is_independent:render("Independent Cast", "Cast independently of the rotation priority")
        end
        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics()
    -- Purify is a self-cast cleansing/healing skill - doesn't need a target
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_data.purify.spell_id);
    if not is_logic_allowed then return false end;

    local local_player = get_local_player();
    if not local_player then return false end;

    -- Check for Crowd Control (CC)
    local buffs = local_player:get_buffs()
    if buffs then
        local cc_hashes = {
            [290962] = true,  -- Frozen
            [1285259] = true, -- Trapped
            [356162] = true,  -- Smoke Bomb
            [39809] = true    -- Generic CC
        }
        for _, buff in ipairs(buffs) do
            if cc_hashes[buff.name_hash] then
                if cast_spell.self(spell_data.purify.spell_id, 0) then
                    console.print("Cast Purify - CC Break");
                    return true;
                end
            end
        end
    end

    local current_hp_pct = local_player:get_current_health() / local_player:get_max_health();
    if current_hp_pct > menu_elements.hp_threshold:get() then
        return false;
    end

    if cast_spell.self(spell_data.purify.spell_id, 0) then
        local current_time = get_time_since_inject();
        next_time_allowed_cast = current_time + menu_elements.cast_delay:get();
        console.print("Cast Purify - Cleansing Activated");
        return true;
    end;

    return false;
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements
}