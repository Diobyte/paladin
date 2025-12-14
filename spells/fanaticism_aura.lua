-- Fanaticism Aura - Aura Skill
-- Offensive aura granting increased Attack Speed to you and nearby allies.
-- META: "Activate Fanaticism Aura as often as possible" (maxroll.gg)

local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

-- Constants
local AURA_DURATION = 12.0  -- Default duration in seconds
local BUFFER_TIME = 1.0      -- Buffer time to recast before aura expires (increased for safety)
local FANATICISM_BUFF_HASH = nil  -- Will be populated if we can detect the buff

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_fanaticism_enabled")),
    recast_interval = slider_float:new(2.0, 60.0, AURA_DURATION - BUFFER_TIME, get_hash("paladin_rotation_fanaticism_recast")),
    combat_only = checkbox:new(true, get_hash("paladin_rotation_fanaticism_combat_only")),
    enemy_type_filter = combo_box:new(0, get_hash("paladin_rotation_fanaticism_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_fanaticism_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_fanaticism_min_weight")),
}

local next_time_allowed_cast = 0.0
local last_cast_time = 0.0
local is_aura_active = false

-- Check if player has fanaticism buff active
local function has_fanaticism_buff()
    local player = get_local_player()
    if not player then return false end
    
    local buffs = player:get_buffs()
    if not buffs then return false end
    
    -- Check for fanaticism-related buff names/hashes
    -- The buff might be named differently, check common patterns
    for _, buff in ipairs(buffs) do
        local name = buff:get_name() or ""
        -- Look for fanaticism or attack speed related buffs
        if name:lower():find("fanatic") or name:lower():find("attack_speed") then
            return true, buff:get_remaining_time()
        end
    end
    
    return false, 0
end

local function safe_menu_text(value)
    if menu_elements.tree_tab and type(menu_elements.tree_tab.text) == "function" then
        pcall(function()
            menu_elements.tree_tab:text(value)
        end)
        return
    end

    if ui and type(ui.text) == "function" then
        pcall(function()
            ui.text(value)
        end)
        return
    end

    if text and type(text) == "function" then
        pcall(function()
            text(value)
        end)
        return
    end
end

local function menu()
    if menu_elements.tree_tab:push("Fanaticism Aura") then
        menu_elements.main_boolean:render("Enable", "Offensive Aura - Attack Speed buff")
        if menu_elements.main_boolean:get() then
            menu_elements.combat_only:render("Combat Only", "Only use Fanaticism Aura in combat")
            menu_elements.recast_interval:render("Recast Interval", "Time between recasts (seconds). Set to 0 to only recast when aura expires.", 1)
            
            menu_elements.enemy_type_filter:render("Enemy Type Filter", {"All", "Elite+", "Boss"}, "")
            menu_elements.use_minimum_weight:render("Use Minimum Weight", "")
            if menu_elements.use_minimum_weight:get() then
                menu_elements.minimum_weight:render("Minimum Weight", "", 1)
            end

            -- Display aura status
            local now = my_utility.safe_get_time()
            local time_since_cast = now - last_cast_time
            local time_remaining = math.max(0, AURA_DURATION - time_since_cast)
            
            if is_aura_active and time_remaining > 0 then
                safe_menu_text(string.format("Status: Active (%.1fs remaining)", time_remaining))
            else
                safe_menu_text("Status: Inactive")
            end
        end
        menu_elements.tree_tab:pop()
    end
end

local function is_in_combat()
    if not menu_elements.combat_only:get() then
        return true  -- Always return true if combat-only is disabled
    end
    
    local player = get_local_player and get_local_player() or nil
    if not player then return false end
    
    -- Check for enemies within 30 units
    return my_utility.enemy_count_in_radius(30.0, player:get_position()) > 0
end

local function logics()
    local spell_id = spell_data.fanaticism_aura.spell_id
    
    if not menu_elements.main_boolean:get() then 
        is_aura_active = false
        return false, 0 
    end
    
    -- Check if spell is allowed (basic checks)
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    
    if not is_logic_allowed then 
        is_aura_active = false
        return false, 0
    end
    
    -- Combat only check
    if not is_in_combat() then
        is_aura_active = false
        return false, 0
    end

    local now = my_utility.safe_get_time()
    local time_since_cast = now - last_cast_time
    
    -- First, try to detect actual buff on player (more reliable)
    local has_buff, buff_remaining = has_fanaticism_buff()
    if has_buff and buff_remaining > BUFFER_TIME then
        is_aura_active = true
        return false, 0  -- Buff is still active
    end
    
    -- Check if we need to recast based on timing (fallback)
    local recast_interval = menu_elements.recast_interval:get()
    local should_recast = recast_interval > 0 and time_since_cast >= recast_interval
    local is_expiring = time_since_cast >= (AURA_DURATION - BUFFER_TIME)
    
    -- If buff detection didn't find anything but timing says we're fine, trust timing
    if not should_recast and not is_expiring and last_cast_time > 0 then
        is_aura_active = true
        return false, 0
    end
    
    if now < next_time_allowed_cast then 
        is_aura_active = false
        local wait_time = next_time_allowed_cast - now
        return false, wait_time
    end

    if cast_spell and type(cast_spell.self) == "function" then
        if cast_spell.self(spell_id, 0.0) then
            last_cast_time = now
            next_time_allowed_cast = now + 1.0  -- Small cooldown between attempts
            is_aura_active = true
            return true, 1.0
        end
    end

    is_aura_active = false
    return false, 0
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    is_aura_active = function() return is_aura_active end,
    get_remaining_duration = function() 
        return math.max(0, AURA_DURATION - (my_utility.safe_get_time() - last_cast_time)) 
    end,
}
