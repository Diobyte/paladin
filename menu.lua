-- =====================================================
-- PALADIN ROTATION MENU CONFIGURATION
-- =====================================================
-- 
-- TARGETING ARCHITECTURE:
-- 1. SCAN_RADIUS: How far to look for enemies (global setting)
--    - evaluate_all_targets() uses this to build the target list
--    - Should be larger than any spell's cast range
--
-- 2. SPELL CAST RANGE: Each spell has its own range setting
--    - If target is within spell's range → cast
--    - If target is outside spell's range → move toward target
--
-- 3. WEIGHTED TARGETING: Within scan radius, pick BEST target
--    - Prioritizes elites/bosses based on weights
--    - Considers clustering for AoE value
--
-- =====================================================

local menu_elements =
{
    main_boolean        = checkbox:new(true, get_hash("paladin_rotation_main_boolean")),
    main_tree           = tree_node:new(0),

    -- =====================================================
    -- GLOBAL SETTINGS
    -- =====================================================
    settings_tree       = tree_node:new(1),
    
    -- SCAN RADIUS: Maximum range to search for potential targets
    -- This should be LARGER than any spell's individual cast range
    -- Enemies within this radius are considered for targeting
    -- Movement happens when target is outside a spell's specific range
    scan_radius = slider_int:new(5, 30, 15, get_hash("paladin_rotation_scan_radius_v2")),
    
    -- Legacy setting - kept for backwards compatibility
    max_targeting_range = slider_int:new(5, 30, 15, get_hash("paladin_rotation_max_targeting_range")),
    
    prefer_elites       = checkbox:new(true, get_hash("paladin_rotation_prefer_elites")),
    treat_elite_as_boss = checkbox:new(true, get_hash("paladin_rotation_treat_elite_as_boss")),
    cluster_radius      = slider_float:new(2.0, 15.0, 6.0, get_hash("paladin_rotation_cluster_radius")),
    combo_enemy_count   = slider_int:new(1, 15, 4, get_hash("paladin_rotation_combo_enemy_count")),
    combo_window        = slider_float:new(0.1, 2.0, 0.8, get_hash("paladin_rotation_combo_window")),
    rally_resource_pct  = slider_float:new(0.0, 1.0, 0.40, get_hash("paladin_rotation_rally_resource_pct")),
    holy_bolt_resource_pct = slider_float:new(0.0, 1.0, 0.35, get_hash("paladin_rotation_holy_bolt_resource_pct")),
    boss_defiance_hp_pct = slider_float:new(0.0, 1.0, 0.50, get_hash("paladin_rotation_boss_defiance_hp_pct")),

    -- =====================================================
    -- DEBUG SETTINGS
    -- =====================================================
    debug_tree          = tree_node:new(1),
    enable_debug        = checkbox:new(false, get_hash("paladin_rotation_enable_debug")),
    melee_debug_mode    = checkbox:new(false, get_hash("paladin_rotation_melee_debug_mode")),
    bypass_equipped_check = checkbox:new(false, get_hash("paladin_rotation_bypass_equipped_check")),

    -- Manual Play Mode - disables automatic movement
    manual_play         = checkbox:new(false, get_hash("paladin_rotation_manual_play")),

    -- =====================================================
    -- SPELL TREES
    -- =====================================================
    active_spells_tree  = tree_node:new(1),
    inactive_spells_tree = tree_node:new(1),

    -- =====================================================
    -- WEIGHTED TARGETING SYSTEM
    -- Controls HOW targets are prioritized within scan radius
    -- =====================================================
    weighted_targeting_tree = tree_node:new(1),
    weighted_targeting_enabled = checkbox:new(true, get_hash("paladin_rotation_weighted_targeting_enabled")),
    weighted_targeting_debug = checkbox:new(false, get_hash("paladin_rotation_weighted_targeting_debug")),
    
    -- Scan refresh rate (how often to re-evaluate targets)
    scan_refresh_rate = slider_float:new(0.1, 1.0, 0.2, get_hash("paladin_rotation_scan_refresh_rate")),
    
    -- Minimum targets to consider
    min_targets = slider_int:new(1, 10, 1, get_hash("paladin_rotation_min_targets")),
    
    -- Comparison radius: cluster scoring range
    comparison_radius = slider_float:new(0.1, 6.0, 3.0, get_hash("paladin_rotation_comparison_radius")),
    
    -- Custom Enemy Sliders
    custom_enemy_sliders_enabled = checkbox:new(false, get_hash("paladin_rotation_custom_enemy_sliders_enabled")),
    
    -- Target Count sliders
    normal_target_count = slider_int:new(1, 10, 1, get_hash("paladin_rotation_normal_target_count")),
    champion_target_count = slider_int:new(1, 10, 5, get_hash("paladin_rotation_champion_target_count")),
    elite_target_count = slider_int:new(1, 10, 5, get_hash("paladin_rotation_elite_target_count")),
    boss_target_count = slider_int:new(1, 10, 5, get_hash("paladin_rotation_boss_target_count")),
    
    -- Target weights
    boss_weight = slider_int:new(1, 100, 50, get_hash("paladin_rotation_boss_weight")),
    elite_weight = slider_int:new(1, 100, 10, get_hash("paladin_rotation_elite_weight")),
    champion_weight = slider_int:new(1, 100, 15, get_hash("paladin_rotation_champion_weight")),
    any_weight = slider_int:new(1, 100, 2, get_hash("paladin_rotation_any_weight")),
    
    -- Custom Buff Weights
    custom_buff_weights_enabled = checkbox:new(false, get_hash("paladin_rotation_custom_buff_weights_enabled")),
    damage_resistance_provider_weight = slider_int:new(1, 100, 30, get_hash("paladin_rotation_damage_resistance_provider_weight")),
    damage_resistance_receiver_penalty = slider_int:new(0, 20, 5, get_hash("paladin_rotation_damage_resistance_receiver_penalty")),
    horde_objective_weight = slider_int:new(1, 100, 50, get_hash("paladin_rotation_horde_objective_weight")),
    vulnerable_debuff_weight = slider_int:new(1, 5, 1, get_hash("paladin_rotation_vulnerable_debuff_weight")),
    
    -- =====================================================
    -- VISIBILITY & ELEVATION FILTERING
    -- =====================================================
    visibility_tree = tree_node:new(1),
    enable_floor_filter = checkbox:new(true, get_hash("paladin_rotation_enable_floor_filter")),
    floor_height_threshold = slider_float:new(1.0, 15.0, 5.0, get_hash("paladin_rotation_floor_height_threshold")),
    enable_visibility_filter = checkbox:new(true, get_hash("paladin_rotation_enable_visibility_filter")),
    visibility_collision_width = slider_float:new(0.5, 3.0, 1.0, get_hash("paladin_rotation_visibility_collision_width")),
}

return {
    menu_elements = menu_elements,
}
