local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")
local my_target_selector = require("my_utility/my_target_selector")

local max_spell_range = 12.0
local targeting_type = "ranged"
local menu_elements =
{
    tree_tab         = tree_node:new(1),
    main_boolean     = checkbox:new(true, get_hash(my_utility.plugin_label .. "shield_charge_main_bool_base")),
    targeting_mode   = combo_box:new(0, get_hash(my_utility.plugin_label .. "shield_charge_targeting_mode")),
    min_target_range = slider_float:new(0.0, max_spell_range - 1, 0.0,
        get_hash(my_utility.plugin_label .. "shield_charge_min_target_range")),
    min_hits         = slider_int:new(1, 20, 3, get_hash(my_utility.plugin_label .. "shield_charge_min_hits")),
    force_priority   = checkbox:new(true, get_hash(my_utility.plugin_label .. "shield_charge_force_priority")),
    elites_only      = checkbox:new(false, get_hash(my_utility.plugin_label .. "shield_charge_elites_only")),
}

local function menu()
    if menu_elements.tree_tab:push("Shield Charge") then
        menu_elements.main_boolean:render("Enable Spell", "")

        if menu_elements.main_boolean:get() then
            -- Targeting
            menu_elements.targeting_mode:render("Targeting Mode", my_utility.targeting_modes_ranged,
                my_utility.targeting_mode_description)
            menu_elements.min_target_range:render("Min Target Range",
                "Minimum distance to target to allow casting", 1)
            menu_elements.min_hits:render("Min Hits", "Minimum number of enemies to hit to prioritize AOE target", 1)

            -- Logic
            menu_elements.elites_only:render("Elites Only", "Only cast on Elite enemies")
            menu_elements.force_priority:render("Force Priority",
                "Always cast on Boss/Elite/Champion regardless of min range")
        end

        menu_elements.tree_tab:pop()
    end
end

local next_time_allowed_cast = 0;

local function logics(target)
    if not target then return false end;

    local min_hits = menu_elements.min_hits:get()
    local player_pos = get_player_position()
    local aoe_data = my_target_selector.get_most_hits_rectangle(player_pos, max_spell_range, 2.0)

    if aoe_data.is_valid and aoe_data.hits_amount >= min_hits and aoe_data.main_target then
        target = aoe_data.main_target
    end

    if menu_elements.elites_only:get() and not target:is_elite() then return false end
    local menu_boolean = menu_elements.main_boolean:get();
    local is_logic_allowed = my_utility.is_spell_allowed(
        menu_boolean,
        next_time_allowed_cast,
        spell_data.shield_charge.spell_id);

    if not is_logic_allowed then return false end;

    if not my_utility.is_in_range(target, max_spell_range) then
        return false
    end

    -- Logic:
    -- 1. If outside min_range (Gap Close): Cast immediately.
    -- 2. If inside min_range (Boss DPS): Cast only if recast_delay has passed.
    local is_in_min_range = my_utility.is_in_range(target, menu_elements.min_target_range:get())
    local force_priority = menu_elements.force_priority:get()
    local is_priority = my_utility.is_high_priority_target(target)

    if is_in_min_range then
        -- We are in melee range (Boss logic)
        if not (force_priority and is_priority) then return false end

        local current_time = get_time_since_inject()
        local last_cast = my_utility.get_last_cast_time("shield_charge")
        if current_time < last_cast + 2.0 then -- Hardcoded 2.0s delay for Shield Charge weaving
            return false
        end
    end

    if cast_spell.position(spell_data.shield_charge.spell_id, target:get_position(), 0) then
        local current_time = get_time_since_inject();
        local cast_delay = 0.1;
        next_time_allowed_cast = current_time + cast_delay;
        console.print("Cast Shield Charge - Target: " ..
            my_utility.targeting_modes[menu_elements.targeting_mode:get() + 1]);
        return true, cast_delay;
    end;

    return false;
end

return
{
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    targeting_type = targeting_type
}
