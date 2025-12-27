-- local target_selector = require("my_utility/my_target_selector")
local spell_data = require("my_utility/spell_data")

-- Debugging control for console output across modules
local debug_enabled = false

local function set_debug_enabled(val)
    debug_enabled = not not val
end

local function debug_print(...)
    if debug_enabled then
        console.print(...)
    end
end

-- Test-friendly shim: ensure get_hash exists in headless/test env
if rawget(_G, 'get_hash') == nil then
    function get_hash(_) return 0 end
end

-- Safe wrapper for creating a tree tab in environments where the UI is not available (eg. unit tests)
local function safe_tree_tab(index)
    if rawget(_G, 'tree_node') then
        return tree_node:new(index)
    else
        -- fallback object with minimal interface used by spell modules
        return { push = function(self, ...) return false end, pop = function() end }
    end
end

-- Minimal UI stub generator for headless/test environment
local function make_ui_stub(default)
    local val = default
    return {
        get = function() return val end,
        set = function(_, v) val = v end,
        render = function(...) end
    }
end

local function safe_checkbox(default, hash)
    if rawget(_G, 'checkbox') then
        return checkbox:new(default, hash)
    end
    return make_ui_stub(default)
end

local function safe_slider_float(minv, maxv, default, hash)
    if rawget(_G, 'slider_float') then
        return slider_float:new(minv, maxv, default, hash)
    end
    return make_ui_stub(default)
end

local function safe_slider_int(minv, maxv, default, hash)
    if rawget(_G, 'slider_int') then
        return slider_int:new(minv, maxv, default, hash)
    end
    return make_ui_stub(default)
end

local function safe_combobox(options, default, hash)
    if rawget(_G, 'combobox') then
        return combobox:new(options, default, hash)
    end
    return make_ui_stub(default)
end

local function safe_combo_box(default, hash)
    if rawget(_G, 'combo_box') then
        return combo_box:new(default, hash)
    end
    return make_ui_stub(default)
end

local function safe_button(label, fn)
    if rawget(_G, 'button') then
        return button:new(label, fn)
    end
    return { render = function(...) end }
end

-- Spell cast history and helpers (moved up so internal helpers are available during other functions)
local spell_cast_history = {}

local function record_spell_cast(spell_name)
    spell_cast_history[spell_name] = (type(get_time_since_inject) == 'function') and get_time_since_inject() or 0
end

local function reset_spell_cast_tracking()
    spell_cast_history = {}
end

local function get_last_cast_time(spell_name)
    return spell_cast_history[spell_name] or 0
end

-- Try to maintain a buff by casting it on cooldown when the menu option is enabled.
-- Returns:
--   true, delay  -> buff was cast and caller should set next_time_allowed_cast = now + delay
--   false, 0     -> menu enabled but cast attempt failed (not ready/affordable)
--   nil          -> menu option not enabled; caller should continue normal logic
local function try_maintain_buff(spell_name, spell_id, menu_elements, min_delay)
    if not menu_elements or not menu_elements.cast_on_cooldown then
        return nil
    end

    if not menu_elements.cast_on_cooldown:get() then
        return nil
    end

    -- Check if buff is already active to prevent spamming
    -- Since spell_id != buff_id and we don't have correct buff IDs, we use a timer-based approach
    -- if the spell has a duration defined in spell_data.
    local spell_info = spell_data[spell_name]
    if spell_info and spell_info.duration then
        local last_cast = get_last_cast_time(spell_name)
        if last_cast > 0 then
            local current_time = get_time_since_inject()
            -- If we cast it recently and the duration hasn't expired, assume buff is active
            -- Add a small buffer (e.g. 0.5s) to recast slightly before expiration if desired,
            -- or just strictly check duration.
            if current_time < last_cast + spell_info.duration then
                return false, 0
            end
        end
    end

    -- If utility exists, check readiness; otherwise be permissive and attempt cast
    if type(utility) == "table" and not utility.is_spell_ready(spell_id) then
        return false, 0
    end

    -- Guard against environment without cast_spell
    if type(cast_spell) ~= "table" or type(cast_spell.self) ~= "function" then
        return false, 0
    end

    local cast_delay = 0
    if spell_data[spell_name] and spell_data[spell_name].cast_delay then
        cast_delay = spell_data[spell_name].cast_delay
    end

    if cast_spell.self(spell_id, cast_delay) then
        -- record and return a small delay to avoid spam
        record_spell_cast(spell_name)
        local delay = min_delay or 0.1
        return true, delay
    end

    return false, 0
end

-- Helper: compute total cooldown reduction from equipped items (percentage, e.g., 25 = 25%)
local function get_total_cooldown_reduction_pct()
    local local_player = get_local_player()
    if not local_player or type(local_player.get_equipped_items) ~= 'function' then return 0 end
    local equipped_items = local_player:get_equipped_items() or {}
    local cdr_total = 0
    for _, item in ipairs(equipped_items) do
        if item and type(item.get_affixes) == 'function' then
            local affixes = item:get_affixes()
            for _, aff in ipairs(affixes) do
                if aff and type(aff.get_name) == 'function' and type(aff.get_roll) == 'function' then
                    local name = aff:get_name()
                    local roll = aff:get_roll() or 0
                    if type(name) == 'string' and (name:find("Cooldown Reduction") or name:find("cooldown_reduction")) then
                        cdr_total = cdr_total + roll
                    end
                end
            end
        end
    end
    -- Safety cap to avoid negative/absurd cooldowns
    if cdr_total > 75 then cdr_total = 75 end
    return cdr_total
end

-- Generic simple helper to attempt a cast and centralize recording/logging.
-- cast_fn is a function that actually performs the cast (should return true on success).
-- Returns: true, delay on success, false on failure.
-- NOTE: Cooldown enforcement removed to allow spell-specific custom cooldowns to work.
-- Each spell manages its own next_time_allowed_cast timing with custom/default values.
local function try_cast_spell(spell_name, spell_id, menu_boolean, next_time_allowed, cast_fn, delay)
    if not menu_boolean then return false end

    -- Check game API spell ready state (mana/resources, global cooldown)
    local util = utility or package.loaded['utility']
    if type(util) == "table" and type(util.is_spell_ready) == "function" and not util.is_spell_ready(spell_id) then
        return false
    end
    if type(cast_fn) ~= "function" then return false end

    if cast_fn() then
        -- record internally so we don't depend on a global module reference
        record_spell_cast(spell_name)
        return true, delay or 0.1
    end

    return false
end

local function is_auto_play_enabled()
    -- Guard against missing globals in headless or early-init states
    local ap = rawget(_G, "auto_play")
    local obj = rawget(_G, "objective")
    if type(ap) ~= "table" or type(ap.is_active) ~= "function" or type(ap.get_objective) ~= "function" then
        return false
    end

    local objective_fight = obj and obj.fight
    local is_auto_play_active = ap:is_active()
    local auto_play_objective = ap:get_objective()
    local is_auto_play_fighting = objective_fight ~= nil and auto_play_objective == objective_fight
    return is_auto_play_active and is_auto_play_fighting
end

local mount_buff_name = "Generic_SetCannotBeAddedToAITargetList";
local mount_buff_name_hash = mount_buff_name;
local mount_buff_name_hash_c = 1923;

local shrine_conduit_buff_name = "Shine_Conduit";
local shrine_conduit_buff_name_hash = shrine_conduit_buff_name;
local shrine_conduit_buff_name_hash_c = 421661;

local function is_spell_active(spell_id)
    -- get player buffs
    local local_player = get_local_player()
    if not local_player then return false end
    local local_player_buffs = local_player:get_buffs()
    if not local_player_buffs then return false end

    -- Check each buff for a matching spell ID
    for _, buff in ipairs(local_player_buffs) do
        if buff.name_hash == spell_id then
            return true
        end
    end

    return false
end

local function is_buff_active(spell_id, buff_id, min_stack_count)
    -- set default set count to 1 if not passed
    min_stack_count = min_stack_count or 1

    -- get player buffs
    local local_player = get_local_player()
    if not local_player then return false end
    local local_player_buffs = local_player:get_buffs()
    if not local_player_buffs then return false end

    -- for every buff
    for _, buff in ipairs(local_player_buffs) do
        -- if we have a matching spell and buff id and
        -- we have at least the minimum amount of stack or the buff has more than 0.2 seconds remaining
        if buff.name_hash == spell_id and buff.type == buff_id and (buff.stacks >= min_stack_count or buff:get_remaining_time() > 0.2) then
            return true
        end
    end

    return false
end

local function buff_stack_count(spell_id, buff_id)
    -- get player buffs
    local local_player = get_local_player()
    if not local_player then return 0 end
    local local_player_buffs = local_player:get_buffs()
    if not local_player_buffs then return 0 end

    -- iterate over each buff
    for _, buff in ipairs(local_player_buffs) do
        -- check for matching spell and buff id
        if buff.name_hash == spell_id and buff.type == buff_id then
            -- return the stack amount immediately
            return buff.stacks
        end
    end

    -- return 0 if no matching buff is found
    return 0
end

local function is_action_allowed()
    -- evade abort
    local local_player = get_local_player();
    if not local_player then
        return false
    end

    local player_position = local_player:get_position();
    if evade.is_dangerous_position(player_position) then
        return false;
    end

    local busy_spell_id_1 = 197833
    local active_spell_id = local_player:get_active_spell_id()
    if active_spell_id == busy_spell_id_1 then
        return false
    end

    local is_mounted = false;
    local is_blood_mist = false;
    local is_shrine_conduit = false;
    local local_player_buffs = local_player:get_buffs();
    if local_player_buffs then
        for _, buff in ipairs(local_player_buffs) do
            if buff.name_hash == mount_buff_name_hash_c then
                is_mounted = true;
                break;
            end

            if buff.name_hash == shrine_conduit_buff_name_hash_c then
                is_shrine_conduit = true;
                break;
            end
        end
    end

    -- do not make any actions while in blood mist
    if is_blood_mist or is_mounted or is_shrine_conduit then
        -- console.print("Blocking Actions for Some Buff");
        return false;
    end

    return true
end

local function is_spell_allowed(spell_enable_check, next_cast_allowed_time, spell_id)
    if not spell_enable_check then
        return false;
    end;

    local current_time = get_time_since_inject();
    if current_time < next_cast_allowed_time then
        return false;
    end;

    local util = utility or package.loaded['utility']
    if type(util) == 'table' then
        if type(util.is_spell_ready) == 'function' and not util.is_spell_ready(spell_id) then
            return false
        end

        if type(util.is_spell_affordable) == 'function' and not util.is_spell_affordable(spell_id) then
            return false;
        end

        if type(util.can_cast_spell) == 'function' and not util.can_cast_spell(spell_id) then
            return false;
        end
    end;

    -- evade abort
    local local_player = get_local_player();
    if local_player then
        local player_position = local_player:get_position();
        if evade.is_dangerous_position(player_position) then
            return false;
        end
    end

    if is_auto_play_enabled() then
        return true;
    end

    local ow = rawget(_G, "orbwalker")
    if type(ow) ~= "table" or type(ow.get_orb_mode) ~= "function" then
        -- In environments without the orbwalker (or not yet initialized), allow auto-play to continue
        return is_auto_play_enabled()
    end

    local current_orb_mode = ow.get_orb_mode()

    if current_orb_mode == orb_mode.none then
        return false
    end

    local is_current_orb_mode_pvp = current_orb_mode == orb_mode.pvp
    local is_current_orb_mode_clear = current_orb_mode == orb_mode.clear

    -- is pvp or clear (both)
    if not is_current_orb_mode_pvp and not is_current_orb_mode_clear then
        return false;
    end

    -- we already checked everything that we wanted. If orb = none, we return false.
    -- PVP only & not pvp mode, return false . PvE only and not pve mode, return false.
    -- All checks passed at this point so we can go ahead with the logics

    return true
end

local function generate_points_around_target(target_position, radius, num_points)
    local points = {};
    for i = 1, num_points do
        local angle = (i - 1) * (2 * math.pi / num_points);
        local x = target_position:x() + radius * math.cos(angle);
        local y = target_position:y() + radius * math.sin(angle);
        table.insert(points, vec3.new(x, y, target_position:z()));
    end
    return points;
end

local function get_best_point(target_position, circle_radius, current_hit_list)
    local points = generate_points_around_target(target_position, circle_radius * 0.75, 8); -- Generate 8 points around target
    local hit_table = {};

    local player_position = get_player_position();
    for _, point in ipairs(points) do
        local hit_list = utility.get_units_inside_circle_list(point, circle_radius);

        local hit_list_collision_less = {};
        for _, obj in ipairs(hit_list) do
            local is_wall_collision = target_selector.is_wall_collision(player_position, obj, 2.0);
            if not is_wall_collision then
                table.insert(hit_list_collision_less, obj);
            end
        end

        table.insert(hit_table, {
            point = point,
            hits = #hit_list_collision_less,
            victim_list = hit_list_collision_less
        });
    end

    -- sort by the number of hits
    table.sort(hit_table, function(a, b) return a.hits > b.hits end);

    local current_hit_list_amount = #current_hit_list;
    if hit_table[1].hits > current_hit_list_amount then
        return hit_table[1]; -- returning the point with the most hits
    end

    return { point = target_position, hits = current_hit_list_amount, victim_list = current_hit_list };
end

function is_target_within_angle(origin, reference, target, max_angle)
    local to_reference = (reference - origin):normalize();
    local to_target = (target - origin):normalize();
    local dot_product = to_reference:dot(to_target);

    -- Guard against tiny floating point errors that can push dot slightly outside [-1,1]
    -- which would make math.acos return NaN. Clamp to safe range.
    if dot_product ~= dot_product then
        -- If dot is NaN for any reason, default to 1 (colinear) to avoid NaN propagation.
        dot_product = 1
    end
    if dot_product > 1 then
        dot_product = 1
    elseif dot_product < -1 then
        dot_product = -1
    end

    local angle = math.deg(math.acos(dot_product));
    return angle <= max_angle;
end

local function generate_points_around_target_rec(target_position, radius, num_points)
    local points = {}
    local angles = {}
    for i = 1, num_points do
        local angle = (i - 1) * (2 * math.pi / num_points)
        local x = target_position:x() + radius * math.cos(angle)
        local y = target_position:y() + radius * math.sin(angle)
        table.insert(points, vec3.new(x, y, target_position:z()))
        table.insert(angles, angle)
    end
    return points, angles
end

local function get_best_point_rec(target_position, rectangle_radius, width, current_hit_list)
    local points, angles = generate_points_around_target_rec(target_position, rectangle_radius, 8)
    local hit_table = {}

    for i, point in ipairs(points) do
        local angle = angles[i]
        -- Calculate the destination point based on width and angle
        local destination = vec3.new(point:x() + width * math.cos(angle), point:y() + width * math.sin(angle), point:z())

        local hit_list = utility.get_units_inside_rectangle_list(point, destination, width)
        table.insert(hit_table, { point = point, hits = #hit_list, victim_list = hit_list })
    end

    table.sort(hit_table, function(a, b) return a.hits > b.hits end)

    local current_hit_list_amount = #current_hit_list
    if hit_table[1].hits > current_hit_list_amount then
        return hit_table[1] -- returning the point with the most hits
    end

    return { point = target_position, hits = current_hit_list_amount, victim_list = current_hit_list }
end

-- Check whether player has a shield equipped (used for spells that require a shield)
local function has_shield()
    local local_player = get_local_player()
    if not local_player then return false end
    local items = nil
    if type(local_player.get_equipped_items) == 'function' then
        items = local_player:get_equipped_items()
    end
    if not items then return false end

    for _, item in ipairs(items) do
        if item then
            -- Check name heuristics
            if type(item.get_name) == 'function' then
                local name = item:get_name()
                if type(name) == 'string' and name:lower():match('shield') then
                    return true
                end
            end

            -- Check item type heuristics
            if type(item.get_item_type) == 'function' then
                local itype = item:get_item_type()
                if type(itype) == 'string' and itype:lower():match('shield') then
                    return true
                end
            elseif type(item.item_type) == 'string' and item.item_type:lower():match('shield') then
                return true
            end
        end
    end

    return false
end

local function enemy_count_in_range(evaluation_range, source_position)
    -- set default source position to player position
    local source_position = source_position or get_player_position();
    local enemies = target_selector.get_near_target_list(source_position, evaluation_range);
    local all_units_count = 0;
    local normal_units_count = 0;
    local elite_units_count = 0;
    local champion_units_count = 0;
    local boss_units_count = 0;

    for _, obj in ipairs(enemies) do
        -- Only count valid targetable enemies
        if obj and obj:is_enemy() and not obj:is_untargetable() and not obj:is_immune() then
            if obj:is_boss() then
                boss_units_count = boss_units_count + 1;
            elseif obj:is_champion() then
                champion_units_count = champion_units_count + 1;
            elseif obj:is_elite() then
                elite_units_count = elite_units_count + 1;
            else
                normal_units_count = normal_units_count + 1;
            end
            all_units_count = all_units_count + 1;
        end
    end;
    return all_units_count, normal_units_count, elite_units_count, champion_units_count, boss_units_count
end

local function get_melee_range()
    local melee_range = 2

    -- Paladin does not have a dash buff that increases melee range like Spiritborn's Ravager
    -- if is_buff_active(spell_data.shield_charge.spell_id, spell_data.shield_charge.buff_ids.dash) then
    --     melee_range = 7
    -- end

    return melee_range
end

local function is_in_range(target, range)
    if not target or not target.get_position then return false end
    local target_position = target:get_position()
    local player_position = get_player_position()
    local target_distance_sqr = player_position:squared_dist_to_ignore_z(target_position)
    local range_sqr = (range * range)
    return target_distance_sqr < range_sqr
end

local function is_high_priority_target(target)
    if not target then return false end
    return target:is_elite() or target:is_champion() or target:is_boss()
end

local function enemy_count_simple(range)
    local player_position = get_player_position()
    local enemies = actors_manager.get_enemy_npcs()
    local count = 0
    for _, enemy in ipairs(enemies) do
        local enemy_position = enemy:get_position()
        local distance_sqr = player_position:squared_dist_to_ignore_z(enemy_position)
        if distance_sqr < (range * range) then
            count = count + 1
        end
    end
    return count
end

local spell_delays = {
    -- NOTE: if a regular cast is used, it means even instant abilities will be on cooldown for the duration of the regular cast, not optimal
    instant_cast = 0.01, -- instant cast abilites should be used as soon as possible
    regular_cast = 0.1   -- regular abilites with animation should be used with a delay
}

-- skin name patterns for infernal horde objectives
local horde_objectives = {
    "BSK_HellSeeker",
    "MarkerLocation_BSK_Occupied",
    "S05_coredemon",
    "S05_fallen",
    "BSK_Structure_BonusAether",
    "BSK_Miniboss",
    "BSK_elias_boss",
    "BSK_cannibal_brute_boss",
    "BSK_skeleton_boss"
}

local evaluation_range_description = "\n      Range to check for enemies around the player      \n\n"

local targeting_modes = {
    "Ranged Target",             -- 0
    "Ranged Target (in sight)",  -- 1
    "Melee Target",              -- 2
    "Melee Target (in sight)",   -- 3
    "Closest Target",            -- 4
    "Closest Target (in sight)", -- 5
    "Best Cursor Target",        -- 6
    "Closest Cursor Target"      -- 7
}

local targeting_modes_melee = {
    "Melee Target",              -- 0 (Maps to 2)
    "Melee Target (in sight)",   -- 1 (Maps to 3)
    "Closest Target",            -- 2 (Maps to 4)
    "Closest Target (in sight)", -- 3 (Maps to 5)
    "Best Cursor Target",        -- 4 (Maps to 6)
    "Closest Cursor Target"      -- 5 (Maps to 7)
}

local targeting_modes_ranged = {
    "Ranged Target",             -- 0 (Maps to 0)
    "Ranged Target (in sight)",  -- 1 (Maps to 1)
    "Closest Target",            -- 2 (Maps to 4)
    "Closest Target (in sight)", -- 3 (Maps to 5)
    "Best Cursor Target",        -- 4 (Maps to 6)
    "Closest Cursor Target"      -- 5 (Maps to 7)
}

local activation_filters = {
    "Any Enemy",         -- 0
    "Elite & Boss Only", -- 1
    "Boss Only"          -- 2
}

local targeting_mode_description =
    "       Ranged Target: Targets the most valuable enemy within max range (set in settings)     \n" ..
    "       Ranged Target (in sight): Targets the most valuable visible enemy within max range     \n" ..
    "       Melee Target: Targets the most valuable enemy within melee range     \n" ..
    "       Melee Target (in sight): Targets the most valuable visible enemy within melee range     \n" ..
    "       Closest Target: Targets the closest enemy to the player      \n" ..
    "       Closest Target (in sight): Targets the closest visible enemy to the player      \n" ..
    "       Best Cursor Target: Targets the most valuable enemy around the cursor      \n" ..
    "       Closest Cursor Target: Targets the enemy nearest to the cursor      \n"



local plugin_label = "DIRTYDIO_PLUGIN_"

return
{
    spell_delays = spell_delays,
    activation_filters = activation_filters,
    targeting_mode_description = targeting_mode_description,
    targeting_modes = targeting_modes,
    targeting_modes_melee = targeting_modes_melee,
    targeting_modes_ranged = targeting_modes_ranged,
    evaluation_range_description = evaluation_range_description,
    plugin_label = plugin_label,
    is_spell_allowed = is_spell_allowed,
    is_action_allowed = is_action_allowed,
    is_spell_active = is_spell_active,
    is_buff_active = is_buff_active,
    buff_stack_count = buff_stack_count,

    record_spell_cast = record_spell_cast,
    reset_spell_cast_tracking = reset_spell_cast_tracking,
    get_last_cast_time = get_last_cast_time,

    is_auto_play_enabled = is_auto_play_enabled,
    set_debug_enabled = set_debug_enabled,
    debug_print = debug_print,
    safe_tree_tab = safe_tree_tab,
    safe_checkbox = safe_checkbox,
    safe_slider_float = safe_slider_float,
    safe_slider_int = safe_slider_int,
    safe_combobox = safe_combobox,
    safe_combo_box = safe_combo_box,
    safe_button = safe_button,
    try_maintain_buff = try_maintain_buff,
    try_cast_spell = try_cast_spell,
    get_total_cooldown_reduction_pct = get_total_cooldown_reduction_pct,
    has_shield = has_shield,

    get_best_point = get_best_point,
    generate_points_around_target = generate_points_around_target,

    is_target_within_angle = is_target_within_angle,

    get_best_point_rec = get_best_point_rec,
    enemy_count_in_range = enemy_count_in_range,
    enemy_count_simple = enemy_count_simple,
    get_melee_range = get_melee_range,
    is_in_range = is_in_range,
    is_high_priority_target = is_high_priority_target,
    horde_objectives = horde_objectives
}
