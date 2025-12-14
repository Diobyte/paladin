# Paladin Rotation Plugin - AI Coding Guidelines

> **Context:** Diablo 4 Season 11 | Paladin Class ID: 7 | Lua 5.1 syntax
> **Resources:** [Wowhead D4 Skills](https://www.wowhead.com/diablo-4/skills/paladin) for spell IDs
> **Class IDs:** Sorcerer=0, Barbarian=1, Rogue=3, Druid=5, Necromancer=6, Spiritborn/Paladin=7

## Architecture Overview

```
main.lua                 # Entry point: callbacks, spell orchestration, targeting
menu.lua                 # Global menu elements with unique hash IDs
spell_priority.lua       # Ordered priority list (buffs → ultimates → burst → core → generators)
my_utility/
├── my_utility.lua       # is_spell_allowed(), get_resource_pct(), enemy_count_in_radius()
├── spell_data.lua       # Spell IDs, categories, cast_types, faith costs/generation
├── my_target_selector.lua  # Weighted targeting with boss/elite/champion weights
└── buff_cache.lua       # TTL-based buff caching per game object
spells/                  # One file per spell, exports {menu, logics, menu_elements}
```

## Callback Registration

Scripts use two main callbacks registered in `main.lua`:

```lua
-- Menu rendering (UI elements)
on_render_menu(function()
    -- All menu elements must be rendered here
end)

-- Game logic (spell casting, targeting) - runs every frame
on_update(function()
    -- Check orbwalker mode, find targets, cast spells
end)
```

## Spell Module Template

Every spell file in `spells/` **must** follow this pattern:

```lua
local my_utility = require("my_utility/my_utility")
local spell_data = require("my_utility/spell_data")

local menu_elements = {
    tree_tab = tree_node:new(1),
    main_boolean = checkbox:new(true, get_hash("paladin_rotation_SPELLNAME_enabled")),
    min_cooldown = slider_float:new(0.0, 1.0, 0.1, get_hash("paladin_rotation_SPELLNAME_min_cd")),
    -- Common options: engage_range, resource_threshold, enemy_type_filter, prediction_time
}

local spell_id = spell_data.SPELLNAME.spell_id
local next_time_allowed_cast = 0.0

local function menu()
    if menu_elements.tree_tab:push("Spell Name") then
        menu_elements.main_boolean:render("Enable", "Tooltip description")
        -- Render other menu elements when enabled
        menu_elements.tree_tab:pop()
    end
end

local function logics(target)  -- target param only for targeted/position spells
    local menu_boolean = menu_elements.main_boolean:get()
    local is_logic_allowed = my_utility.is_spell_allowed(menu_boolean, next_time_allowed_cast, spell_id)
    if not is_logic_allowed then return false, 0 end

    -- Add spell-specific conditions here

    local now = my_utility.safe_get_time()
    local cooldown = menu_elements.min_cooldown:get()

    -- Cast based on cast_type (see table below)
    if cast_spell.self(spell_id, 0.0) then  -- or .target() or .position()
        next_time_allowed_cast = now + cooldown
        return true, cooldown
    end
    return false, 0
end

return { menu = menu, logics = logics, menu_elements = menu_elements }
```

## Cast Types Reference

| `cast_type`  | API Call                                     | Examples                                                            |
| ------------ | -------------------------------------------- | ------------------------------------------------------------------- |
| `"self"`     | `cast_spell.self(spell_id, animation_time)`  | Auras, AoE around player (blessed_hammer, condemn, consecration)    |
| `"target"`   | `cast_spell.target(target, spell_id, delay)` | Melee/projectile at unit (holy_bolt, zeal, clash)                   |
| `"position"` | `cast_spell.position(spell_id, pos, delay)`  | Ground-targeted (falling_star, shield_charge, spear_of_the_heavens) |

## Adding a New Spell (Checklist)

1. **`spell_data.lua`**: Add spell entry with `spell_id`, `category`, `cast_type`, `faith_cost` or `faith_gen`
2. **`spells/SPELLNAME.lua`**: Create file following template above
3. **`main.lua` top**: Add `package.loaded["spells/SPELLNAME"] = nil`
4. **`main.lua` spells table**: Add `SPELLNAME = require("spells/SPELLNAME")`
5. **`spell_priority.lua`**: Insert spell name in appropriate tier
6. **`main.lua` spell_params**: Add `SPELLNAME = { args = {best_target} }` or `{ args = {} }` for self-cast
7. **`main.lua` spell_internal_cooldowns**: Add `SPELLNAME = 0.25` (typical: 0.15-0.50s)

## Resource System (Faith)

| Type           | Spells                                             | Faith      |
| -------------- | -------------------------------------------------- | ---------- |
| **Generators** | clash, rally, advance, holy_bolt, brandish         | +14 to +22 |
| **Spenders**   | blessed_hammer, zeal, divine_lance, blessed_shield | -10 to -28 |

Use `my_utility.get_resource_pct()` (returns 0.0-1.0) for threshold checks.

## Critical Conventions

### Menu Hash Format

```lua
get_hash("paladin_rotation_SPELLNAME_SETTING")  -- MUST be unique across plugin
```

### Enemy Type Filter Pattern

```lua
local enemy_type_filter = menu_elements.enemy_type_filter:get()
-- 0 = All, 1 = Elite/Champion/Boss, 2 = Boss only
if enemy_type_filter == 2 and not target:is_boss() then return false, 0 end
if enemy_type_filter == 1 and not (target:is_elite() or target:is_champion() or target:is_boss()) then return false, 0 end
```

### Target Prediction (for moving enemies)

```lua
local prediction_time = menu_elements.prediction_time:get()
if prediction and prediction.get_future_unit_position then
    local predicted_pos = prediction.get_future_unit_position(target, prediction_time)
    if predicted_pos then pos = predicted_pos end
end
```

## Framework API Quick Reference

### Core Globals

```lua
get_local_player()                    -- Returns gameobject or nil
get_player_position()                 -- Returns vec3
get_time_since_inject()               -- Returns float (seconds since script load)
get_hash(str)                         -- Returns unique int for menu elements
get_equipped_spell_ids()              -- Returns table of equipped spell IDs
get_cursor_position()                 -- Returns vec3 of cursor in game world
get_gametime()                        -- Returns current in-game time
```

### Actors Manager

```lua
actors_manager.get_enemy_npcs()       -- Table of enemy gameobjects
actors_manager.get_all_npcs()         -- Table of all NPCs
actors_manager.get_all_players()      -- Table of all players
actors_manager.get_ally_npcs()        -- Table of allied NPCs
actors_manager.get_all_items()        -- Table of lootable items on ground
actors_manager.get_all_actors()       -- Table of ALL actors in memory
```

### Gameobject Methods

```lua
-- Identity & Position
obj:get_id()                          -- Unique identifier (int)
obj:get_position()                    -- vec3 world position
obj:get_skin_name()                   -- String name (useful for identifying specific mobs)
obj:get_direction()                   -- vec3 facing direction
obj:is_moving() / :is_dashing()       -- Movement state checks

-- Classification
obj:is_enemy()                        -- Is hostile to player
obj:is_boss()                         -- Is a boss enemy
obj:is_elite()                        -- Is elite enemy
obj:is_champion()                     -- Is champion enemy
obj:is_minion()                       -- Is a minion
obj:is_dead()                         -- Is dead
obj:is_immune()                       -- Currently immune to damage
obj:is_vulnerable()                   -- Has vulnerable debuff
obj:is_untargetable()                 -- Cannot be targeted

-- Health & Resources
obj:get_current_health()              -- Current HP (float)
obj:get_max_health()                  -- Max HP (float)
obj:get_primary_resource_current()    -- Current resource (Faith for Paladin)
obj:get_primary_resource_max()        -- Max resource

-- Buffs
obj:get_buffs()                       -- Table of buff objects
-- Buff object properties:
--   buff.name_hash (int), buff.duration, buff:get_remaining_time()
--   buff:is_active_buff(), buff:get_name()

-- Spells
obj:get_active_spell_id()             -- Currently casting spell ID
obj:is_spell_ready(spell_id)          -- Is spell off cooldown
obj:has_enough_resources_for_spell(spell_id) -- Can afford spell
```

### Vec3 Methods

```lua
-- Distance calculations (use squared for performance)
pos:dist_to(other)                    -- Euclidean distance (float)
pos:dist_to_ignore_z(other)           -- Distance ignoring height
pos:squared_dist_to(other)            -- Squared distance (faster)
pos:squared_dist_to_ignore_z(other)   -- Squared, no height (PREFERRED)

-- Position manipulation
pos:get_extended(target, distance)    -- Point extended toward target
pos:get_perp_left(origin, factor)     -- Perpendicular left point
pos:get_perp_right(origin, factor)    -- Perpendicular right point
pos:lerp(target, coefficient)         -- Linear interpolation
pos:rotate_around(origin, degrees)    -- Rotate around point

-- Utility
pos:normalize()                       -- Unit vector
pos:length_3d()                       -- Vector length
pos:is_zero()                         -- Check if zero vector
pos:x() / :y() / :z()                 -- Component accessors
```

### Cast Spell API

```lua
-- Self-cast (auras, AoE around player)
cast_spell.self(spell_id, animation_time)
-- Returns: bool (success)

-- Target cast (melee, projectile at unit)
cast_spell.target(target, spell_id, animation_time, is_debug_mode)
-- target: gameobject
-- Returns: bool (success)

-- Position cast (ground-targeted AoE)
cast_spell.position(spell_id, position, animation_time)
-- position: vec3
-- Returns: bool (success)

-- Channel spell management (for channeled abilities)
cast_spell.add_channel_spell(spell_id, start_time, finish_time, cast_target, cast_position, animation_time, interval)
cast_spell.is_channel_spell_active(spell_id)
cast_spell.remove_channel_spell(spell_id)
```

### Orbwalker Modes

```lua
orbwalker.get_orb_mode()              -- Returns current orb_mode enum
orbwalker.set_orbwalker_mode(mode)    -- Set mode (int or enum)

-- orb_mode enum values:
orb_mode.none   -- 0: Idle, no combat
orb_mode.pvp    -- 1: PvP combat mode
orb_mode.flee   -- 2: Running away
orb_mode.clear  -- 3: PvE clearing mode

-- Always check mode before casting:
if orbwalker.get_orb_mode() == orb_mode.none then return end
```

### Utility Functions

```lua
utility.is_spell_ready(spell_id)      -- bool: off cooldown
utility.is_spell_affordable(spell_id) -- bool: enough resource
utility.is_spell_available(spell_id)  -- bool: unlocked/available
utility.is_spell_upgraded(spell_id)   -- bool: has upgrades
utility.get_spell_charges(spell_id)   -- int: current charges
utility.get_spell_max_charges(spell_id) -- int: max charges
```

### Target Selector

```lua
-- Get closest valid enemy
target_selector.get_target_closer(source_pos, max_distance)

-- Get target with lowest HP
target_selector.get_target_low_hp(source_pos, max_distance)

-- Get target with highest HP
target_selector.get_target_most_hp(source_pos, max_distance)

-- AoE targeting (returns area_result with .main_target, .n_hits, .score)
target_selector.get_most_hits_target_circular_area_heavy(source_pos, dist, radius)
target_selector.get_most_hits_target_rectangle_area_heavy(source_pos, length, width)

-- Collision checks
target_selector.is_wall_collision(source_pos, target, width)  -- Wall between points
target_selector.is_unit_collision(source_pos, target, width)  -- Unit blocking path
target_selector.is_valid_enemy(obj)                           -- Valid target check
```

### Prediction

```lua
-- Get where unit will be in X seconds
prediction.get_future_unit_position(unit, time_seconds)
-- Returns: vec3 predicted position

-- Full prediction result for skillshots
prediction.get_prediction_result(target, params, spell_data, debug_mode)
-- Returns: prediction_result with .hitchance, .cast_position, .time_to_hit
```

### Evade Integration

```lua
-- Check if position is dangerous (in spell AoE)
evade.is_dangerous_position(pos)      -- bool

-- Check if path crosses danger zone
evade.is_position_passing_dangerous_zone(target_pos, source_pos)  -- bool

-- ALWAYS check before casting:
local player_pos = get_player_position()
if evade.is_dangerous_position(player_pos) then return end
```

### Pathfinder

```lua
pathfinder.request_move(pos)          -- Optimized move request
pathfinder.force_move(pos)            -- Immediate move (overrides current)
pathfinder.force_move_raw(pos)        -- Direct move command
```

### Console/Debug

```lua
console.print(...)                    -- Print to console (F1 to toggle)
console.print_full(delay, interval, ...) -- Timed/throttled printing
```

### Menu Elements

```lua
-- Checkbox (boolean toggle)
checkbox:new(default_value, unique_hash)
checkbox:render("Label", "Tooltip")
checkbox:get()  -- Returns bool
checkbox:set(value)

-- Slider (numeric range)
slider_int:new(min, max, default, unique_hash)
slider_float:new(min, max, default, unique_hash)
slider:render("Label", "Tooltip", decimal_places)
slider:get()  -- Returns number

-- Combo box (dropdown)
combo_box:new(default_index, unique_hash)
combo_box:render("Label", {"Option1", "Option2", "Option3"}, "Tooltip")
combo_box:get()  -- Returns index (0-based)

-- Tree node (collapsible section)
tree_node:new(depth)  -- 0 = root, 1 = nested
tree_node:push("Section Name")  -- Returns bool if open
tree_node:pop()  -- Must call after push returns true

-- Keybind
keybind:new(default_key, is_toggle, unique_hash)
keybind:render("Label", "Tooltip")
keybind:get_state()  -- Returns bool if active
```

## Development Workflow

- **Hot Reload**: Press `F5` in-game to reload scripts
- **Console**: Press `F1` to toggle, use `console.print()` for debug
- **Debug Mode**: Enable via menu checkbox, logs cast attempts and failures
- **Script Location**: `loader_folder_name\scripts\main.lua`

## Common Patterns & Code Examples

### Safe Player Check

```lua
local player = get_local_player()
if not player then return end
local player_pos = player:get_position()
```

### Distance-Based Enemy Filtering

```lua
local enemies = actors_manager.get_enemy_npcs()
local max_range_sqr = max_range * max_range
for _, enemy in ipairs(enemies) do
    local pos = enemy:get_position()
    if pos:squared_dist_to_ignore_z(player_pos) <= max_range_sqr then
        -- Enemy is in range
    end
end
```

### Wall Collision Check (for charges/dashes)

```lua
if target_selector and target_selector.is_wall_collision then
    if target_selector.is_wall_collision(player_pos, target, 1.20) then
        return false, 0  -- Don't charge into wall
    end
end
```

### Aura/Buff Maintenance Pattern

```lua
local AURA_DURATION = 12.0
local last_cast_time = 0.0

local function logics()
    local now = my_utility.safe_get_time()
    local time_since_cast = now - last_cast_time

    -- Recast when aura about to expire
    if time_since_cast < (AURA_DURATION - 0.5) then
        return false, 0  -- Aura still active
    end

    if cast_spell.self(spell_id, 0.0) then
        last_cast_time = now
        return true, 0.5
    end
    return false, 0
end
```

### Resource Threshold Check

```lua
local threshold = menu_elements.resource_threshold:get()
if threshold > 0 then
    local resource_pct = my_utility.get_resource_pct()
    if resource_pct and (resource_pct * 100) >= threshold then
        return false, 0  -- Have enough resource, don't use generator
    end
end
```

### AoE Enemy Count Check

```lua
local engage_range = menu_elements.engage_range:get()
local engage_sqr = engage_range * engage_range
local min_enemies = menu_elements.min_enemies:get()
local enemies = actors_manager.get_enemy_npcs()
local near = 0

for _, e in ipairs(enemies) do
    if e and e:is_enemy() then
        local pos = e:get_position()
        if pos and pos:squared_dist_to_ignore_z(player_pos) <= engage_sqr then
            near = near + 1
        end
    end
end

if near < min_enemies then return false, 0 end
```

### Safe pcall Pattern (for potentially nil objects)

```lua
local is_enemy = false
if target then
    local ok, res = pcall(function() return target:is_enemy() end)
    is_enemy = ok and res or false
end
```

## Spell Priority Tiers

From `spell_priority.lua` - spells are checked in this order:

1. **Buff Maintenance**: fanaticism_aura, defiance_aura, holy_light_aura
2. **Ultimates**: arbiter_of_justice, heavens_fury, zenith
3. **Burst Cooldowns**: falling_star, spear_of_the_heavens, condemn, consecration
4. **Core Spam**: blessed_hammer (primary DPS)
5. **Alternative Spenders**: blessed_shield, zeal, divine_lance
6. **Generators**: clash, rally, advance, holy_bolt, brandish
7. **Mobility**: shield_charge

## Internal Cooldown System

`main.lua` tracks per-spell ICDs to prevent spam and allow rotation:

```lua
spell_internal_cooldowns = {
    blessed_hammer = 0.15,     -- Core spam - very short
    holy_bolt = 0.15,          -- Generator filler
    arbiter_of_justice = 0.25, -- Ultimates - react fast
    fanaticism_aura = 0.50,    -- Auras - check less often
    shield_charge = 0.50,      -- Mobility - moderate
}
```

## spell_data.lua Entry Format

```lua
spell_name = {
    spell_id = 2107555,        -- From Wowhead
    category = "core",         -- basic, core, aura, valor, justice, ultimate
    cast_type = "self",        -- self, target, position
    damage_type = "holy",      -- holy, physical
    faith_cost = 10,           -- OR faith_gen = 16 for generators
    cooldown = 12.0,           -- Optional: game cooldown in seconds
    duration = 6.0,            -- Optional: for DoTs/buffs
    is_mobility = true,        -- Optional: mobility skill flag
    is_channeled = true,       -- Optional: channeled skill flag
    requires_shield = true,    -- Optional: needs shield equipped
    description = "...",       -- Human-readable description
}
```

## Error Handling & Safety

```lua
-- Always nil-check framework functions
if cast_spell and type(cast_spell.self) == "function" then
    cast_spell.self(spell_id, 0.0)
end

-- Check utility functions exist
if utility and utility.is_spell_ready then
    if not utility.is_spell_ready(spell_id) then return false, 0 end
end

-- Safe menu element access
local function safe_get_menu_element(element, fallback)
    if element and type(element.get) == "function" then
        return element:get()
    end
    return fallback
end
```

## Auto Play Integration

```lua
-- Check if auto_play is controlling the character
local function is_auto_play_enabled()
    local is_active = auto_play and auto_play.is_active and auto_play.is_active()
    local objective = auto_play and auto_play.get_objective and auto_play.get_objective()
    return is_active and objective == objective.fight
end

-- Auto play movement for far targets
if is_auto_play_enabled() and movement_target then
    local target_pos = movement_target:get_position()
    local move_pos = target_pos:get_extended(player_pos, 3.0)
    pathfinder.request_move(move_pos)
end
```

## Graphics API (for debug visualization)

```lua
-- Only use inside on_render() callback
on_render(function()
    -- Draw circle around player
    graphics.circle_3d(player_pos, radius, color_white(255))

    -- Draw text above enemy
    graphics.text_3d("Target", enemy_pos, 16.0, color_red(255))

    -- Draw line between points
    graphics.line(from_pos, to_pos, color_green(255), 2.0)

    -- World to screen conversion
    local screen_pos = graphics.w2s(world_pos)  -- Returns vec2
end)

-- Predefined colors (alpha 0-255)
color_white(alpha) / color_red(alpha) / color_green(alpha) / color_blue(alpha)
color_yellow(alpha) / color_orange(alpha) / color_purple(alpha) / color_cyan(alpha)
```

## World API

```lua
world.is_point_walkable(pos)          -- Can walk to position
world.is_wall(pos)                    -- Is position a wall
world.get_floor_height(pos)           -- Height at position
world.get_current_zone_name()         -- Current zone string
```

## Loot Manager (for item interactions)

```lua
loot_manager.is_lootable_item(obj, exclude_potions, exclude_gold)
loot_manager.is_potion(obj)
loot_manager.is_gold(obj)
loot_manager.loot_item(obj, exclude_potions, exclude_gold)
```

## Key Codes Reference

Common key codes for keybinds:

```lua
0x01 = LMB, 0x02 = RMB, 0x04 = MMB
0x10 = Shift, 0x11 = Ctrl, 0x12 = Alt
0x20 = Space, 0x1B = Escape
0x41-0x5A = A-Z keys
```

## Infernal Horde Objectives

Special skin names to identify horde objectives (from `my_utility.lua`):

```lua
local horde_objectives = {
    "BSK_HellSeeker",
    "MarkerLocation_BSK_Occupied",
    "S05_coredemon",
    "BSK_Structure_BonusAether",
    "BSK_Miniboss",
    "BSK_elias_boss",
}
-- Check: if obj:get_skin_name():find("BSK_") then ... end
```
