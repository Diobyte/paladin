local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

-- Constants
local AURA_DURATION = 12.0  -- Default duration in seconds
local BUFFER_TIME = 0.5      -- Buffer time to recast before aura expires

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_fanaticism_enabled")),
    recast_interval = slider_float:new(2.0, 60.0, AURA_DURATION, get_hash("paladin_rotation_fanaticism_recast")),
    combat_only = checkbox:new(true, get_hash("paladin_rotation_fanaticism_combat_only")),
    enemy_type_filter = combo_box:new(0, {"All", "Elite+", "Boss"}, get_hash("paladin_rotation_fanaticism_enemy_type")),
    use_minimum_weight = checkbox:new(false, get_hash("paladin_rotation_fanaticism_use_min_weight")),
    minimum_weight = slider_float:new(0.0, 50.0, 5.0, get_hash("paladin_rotation_fanaticism_min_weight")),
}

local next_time_allowed_cast = 0.0
local last_cast_time = 0.0
local is_aura_active = false

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
        menu_elements.main_boolean:render("Enable", "Enable Fanaticism Aura")
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
    if not menu_elements.main_boolean:get() then 
        is_aura_active = false
        return false 
    end
    
    if not is_in_combat() then
        is_aura_active = false
        return false
    end

    local now = my_utility.safe_get_time()
    local time_since_cast = now - last_cast_time
    
    -- Check if we need to recast
    local recast_interval = menu_elements.recast_interval:get()
    local should_recast = recast_interval > 0 and time_since_cast >= recast_interval
    local is_expiring = time_since_cast >= (AURA_DURATION - BUFFER_TIME)
    
    if not should_recast and not is_expiring then
        is_aura_active = true
        return false
    end
    
    if now < next_time_allowed_cast then 
        is_aura_active = false
        return false 
    end

    local spell_id = spell_data.fanaticism_aura.spell_id
    if not my_utility.is_spell_ready(spell_id) or not my_utility.is_spell_affordable(spell_id) then
        is_aura_active = false
        return false
    end

    if cast_spell and type(cast_spell.self) == "function" then
        if cast_spell.self(spell_id, 0.0) then
            last_cast_time = now
            next_time_allowed_cast = now + 1.0  -- Small cooldown between attempts
            is_aura_active = true
            
            -- Print debug message if console is available
            if console and type(console.print) == "function" then
                console.print("Paladin_Rotation | Fanaticism Aura cast at " .. os.date("%H:%M:%S"))
            end
            
            return true
        end
    end

    is_aura_active = false
    return false
end

return {
    menu = menu,
    logics = logics,
    menu_elements = menu_elements,
    is_aura_active = function() return is_aura_active end,
    get_remaining_duration = function() 
        return math.max(0, AURA_DURATION - (my_utility.safe_get_time() - last_cast_time)) 
    end
}
