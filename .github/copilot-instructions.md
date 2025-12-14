# Diablo Lua Scripting API Documentation

> [!IMPORTANT] > **Context for AI Assistants:**
>
> - **Game Version:** All scripting logic must be designed for **Diablo 4 Season 11**.
> - **Lua Version:** Adhere strictly to the Lua version and syntax patterns demonstrated in the code examples within this document.
> - **External Resources:** For missing spell IDs, class details, or game mechanics not covered here, refer to the [Wowhead Diablo 4](https://www.wowhead.com/diablo-4) section.

This document contains the aggregated documentation for the Diablo Lua Scripting API.

# **Home**

## Getting Started

- Install your Lua scripts in `loader_folder_name\scripts`.
- Name your script files as `main.lua` (e.g., `scripts\test\main.lua`).
- Reload Lua files in-game with the default key: `F5`.
- Console Toggle Keybind: `F1`

## Documentation Pages

Explore various components of Lua scripting:

- [**Actors Manager**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Actors-Manager): Get quick pre-filtered gameobjects lists.
- [**Callbacks**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Callbacks): Register your code on game events callbacks.
- [**Color**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color): Utilize color in your scripts for enhanced visual representation.
- [**Console**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Console): Learn about printing and debugging in the console.
- [**Enums**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Enums): Enumerators to improve your code readability.
- [**Orbwalker**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Orbwalker): Interact with the orbwalker core module.
- [**Evade**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Evade): Interact with the evade core module.
- [**Game Object**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object): Interacting with gameobjects and their properties.
- [**Global Functions**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Global-Functions): Access global handy functions.
- [**Graphics**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Graphics): Implementing graphical elements in your scripts.
- [**Loot Manager**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Loot-Manager): Interact with the loot manager core module.
- [**Menu Elements**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Menu-Elements): Creating and handling menu elements in scripts.
- [**Pathfinder**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Pathfinder): Interact with the Pathfinder core module.
- [**Prediction**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Prediction): Interact with the Prediction core module.
- [**Target Selector**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Target-Selector): Interact with the Target Selector core module.
- [**Utility**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Utility): Essential utility functions for scripting.
- [**Cast Spell**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Cast-Spell): Spell casting functions.
- [**Vector2**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2): 2D Geometry.
- [**Vector3**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3): 3D Geometry.
- [**World**](https://github.com/qqtnn/diablo_lua_documentation/wiki/World): Interacting with the game's world and environment.
- [**Auto Play**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Auto‐Play): Interact with the auto play core module.

## Where to Begin

Start with the [**Global Functions**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Global-Functions) to understand basic Lua functionality in Diablo. Then, explore [**Game Object**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) to interact with in-game elements. [**Target Selector**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Graphics) to refine target acquisition and [**Graphics**](https://github.com/qqtnn/diablo_lua_documentation/wiki/Graphics) for custom UI elements. As you advance, integrate various components for complex scripting.

## Code Examples:

```lua
-- register on_update callback to call the code each frame
on_update(function()

    -- filter the code to work only with orbwalker runing some mode
    if orbwalker.get_orb_mode() == orb_mode.none then
        return
    end

     -- get player position
     local player_position = get_player_position()

     -- get the closest target to player position
```

---

# **Global Functions**

## Overview

Global Functions are a collection of essential tools for interacting with the game environment. These functions provide streamlined access to player data, game objects, and other crucial aspects of the game.

## Functions

### Get Local Player

`get_local_player()`

> [!NOTE]
> Accesses the game object representing the local player, essential for many player-centric operations.
>
> - Returns: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Player Name

`get_local_player_name()`

> [!NOTE]
> Retrieves Character Name of Local Player.
>
> - Returns: String

### Get Player Position

`get_player_position()`

> [!NOTE]
> Retrieves the current geographical position of the local player in the game world, useful for navigation and positioning strategies.
>
> - Returns: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3)

### Get Actors List

`get_actors_list()`

> [!NOTE]
> Gathers a comprehensive list of all active game actors, providing a broad overview of the entities present in the current game environment.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Attachments List

`get_attachments_list()`

> [!NOTE]
> Fetches a list of all game objects that are currently attached, offering insights into various game entities and their interactions.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Hash

`get_hash(str)`

- `str`: String - The string to be hashed.
  > [!NOTE]
  > Converts a given string into a hash integer, facilitating efficient data storage and retrieval operations.
  >
  > - Returns: Integer

### Get Cursor Position

`get_cursor_position()`

> [!NOTE]
> Obtains the precise position of the cursor in the game world, useful for UI interactions and in-game targeting.
>
> - Returns: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3)

### Get Game Time

`get_gametime()`

> [!NOTE]
> Provides the current in-game time, essential for time-based events and game dynamics.
>
> - Returns: Number

### Get Time Since Inject

`get_time_since_inject()`

> [!NOTE]
> Measures the duration since the last code injection, offering a timing benchmark for scripts and operations.
>
> - Returns: Number

### Get Equipped Spells IDs

`get_equipped_spell_ids()`

> [!NOTE]
>
> - Returns: Table of number (int) spells ids

### Get Name For Spell

`get_name_for_spell(spell_id)`

> spell_id parameter is number(int)

> [!NOTE]
>
> - Returns: Name of the spell sent by parameter

### Is Inventory Open

`is_inventory_open()`

> [!NOTE]
>
> - Returns: Return `Boolean` of inventory open state.

### Get Open Inventory Bag

`get_open_inventory_bag()`

| State       | ID  |
| ----------- | --- |
| Not Open    | -1  |
| Items       | 0   |
| Consumables | 1   |

> [!NOTE]
>
> - Returns: Return `number (int)` indicating which inventory is open.

### Get Key State

`get_key_state(key)`

- `key`: Byte - The key code to check.
  > [!NOTE]
  > Checks if the specified key is currently pressed down.
  >
  > - Returns: Boolean

### Get Quests

`get_quests()`

> [!NOTE]
> Retrieves a table of all active quests in the game.
>
> - Returns: Table of quests

### Get Hovered Item

`get_hovered_item()`

> [!NOTE]
> Fetches the game object that is currently being hovered by the cursor.
>
> - Returns: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Interact With Object

`interact_object(object)`

- `object`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The object to interact with.
  > [!NOTE]
  > Initiates an interaction with the specified game object.
  >
  > - Returns: Boolean (indicates success or failure)

### Interact with Vendor

`interact_vendor(object)`

- `object`: [`game.object`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The vendor object to interact with.

> [!NOTE]
> Initiates an interaction with the specified vendor object.
>
> - Returns: `void`

### Get Screen Width

`get_screen_width()`

> [!NOTE]
> Retrieves the current width of the game screen in pixels.
>
> - Returns: Number

### Get Screen Height

`get_screen_height()`

> [!NOTE]
> Retrieves the current height of the game screen in pixels.
>
> - Returns: Number

### Get Helltide Coin Cinders

`get_helltide_coin_cinders()`

> [!NOTE]
> Retrieves the current count of Helltide coin cinders.
>
> - Returns: Number

### Get Helltide Coin Hearts

`get_helltide_coin_hearts()`

> [!NOTE]
> Retrieves the current count of Helltide coin hearts.
>
> - Returns: Number

### Leave Dungeon

`leave_dungeon()`

> [!NOTE]
> Initiates the action to exit the current dungeon, useful for automating transitions or escaping unfavorable situations.
>
> - Returns: `bool` (indicates success or failure)

### Revive at Checkpoint

`revive_at_checkpoint()`

> [!NOTE]
> Revives the player at the nearest checkpoint.
>
> - Returns: `void`

### Start Game

`start_game()`

> [!NOTE]
> Starts the game session.
>
> - Returns: `void`

### Leave Game

`leave_game()`

> [!NOTE]
> Leaves the current game session.
>
> - Returns: `void`

### Use Health Potion

`use_health_potion()`

> [!NOTE]
> Uses a health potion to restore the player's health.
>
> - Returns: `void`

### Reset All Dungeons

`reset_all_dungeons()`

> [!NOTE]
> Initiates the action to reset dungeons which also kicks you for any dungeon you are into
>
> - Returns: `nil`

### Teleport To Waypoint

`teleport_to_waypoint(id)`

- `id`: `number`- The id of the waypoint to teleport
  > [!NOTE]
  > Initiates the action to teleport to an specific waypoint
  >
  > - Returns: `nil`

> [!TIP]
> Waypoints ID Enum

```lua
local waypoints_enum = {
    GEA_KUL = 0xB66AB,
    IRON_WOLVES_ENCAMPMENT = 0xDEAFC,
    IMPERIAL_LIBRARY = 0x10D63D,
    DENSHAR = 0x8AF45,
    TARSARAK = 0x8C7B7,
    ZARBINZET = 0xA46E5,
    JIRANDAI = 0x462E2,
    ALZUUDA = 0x792DA,
    WEJINHANI = 0x9346B,
    RUINS_OF_RAKHAT_KEEP_INNER_COURT = 0xF77C2,
    THE_TREE_OF_WHISPERS = 0x90557,
    BACKWATER = 0xA491F,
    KED_BARDU = 0x34CE7,
    HIDDEN_OVERLOOK = 0x460D4,
    FATES_RETREAT = 0xEEEB3,
    FAROBRU = 0x2D392,
    TUR_DULRA = 0x8D596,
    MAROWEN = 0x27E01,
    BRAESTAIG = 0x7FD82,
    CERRIGAR = 0x76D58,
    FIREBREAK_MANOR = 0x803EE,
    CORBACH = 0x22EBE,
    TIRMAIR = 0xB92BE,
    UNDER_THE_FAT_GOOSE_INN = 0xEED6B,
    MENESTAD = 0xACE9B,
    KYOVASHAD = 0x6CC71,
    BEAR_TRIBE_REFUGE = 0x8234E,
    MARGRAVE = 0x90A86,
    YELESNA = 0x833F8,
    NEVESK = 0x6D945,
    NOSTRAVA = 0x8547F
}

-- Usage example:
teleport_to_waypoint(waypoints_enum.GEA_KUL)

```

---

# **Callbacks**

## On Render Callback

`on_render()`

> [!NOTE]
> All graphics-related elements (images, circles, rectangles, text) must be placed inside this callback.

## On Update Callback

`on_update()`

> [!NOTE]
> Ideal for most game logics and spell casts.

## On Pre-Tick Callback

`on_pre_tick()`

> [!NOTE]
> Designed for logics requiring anticipation of the next game tick.

## On Render Menu Callback

`on_render_menu()`

> [!NOTE]
> All menu elements must be rendered in this callback.
> [!WARNING]
> All menu elements id must be unique otherwise they will overlap with other menu elements at saving.

```lua
local developer_id = "rename_me";
local check_test = checkbox:new(true, get_hash("developer_id .. "check_test"))

local function my_render_menu()
    check_test:render("Test Checkbox", "");
end

-- register your local function into the callback
on_render_menu(my_render_menu;
```

## On Keys Callbacks

`on_key_press()`
`on_key_release()`

> [!NOTE]
> Triggers when any key is either press or released.

#### Lua Code Examples:

> Register callback into anonimous function

```lua
on_key_release(function(key)
    print("Key Released:", key);
end);
```

> Register callback into a local function

```lua
local function my_on_key_press(key)
    if key == 0x01 then
        console.print("Key Pressed is LMB");
    end;
end

on_key_press(my_on_key_press);
```

---

# **Console**

## Basic and Advanced Console Printing

Our console comes with two handy functions for displaying text: `console.print` for your regular printing needs and `console.print_full` when you need something a bit more sophisticated, like timed and repeated messages.

### Console Print

`console.print(...)`

> [!NOTE]
> The `console.print` function is utilized for standard console output. It efficiently handles various data types such as integers, strings, and floating-point numbers. This function is ideal for simple debugging or displaying information.
>
> **Example:**
>
> ```lua
> console.print(123, "hello", 3222, 322.0)
> ```
>
> Output: `123 hello 3222 322.0`

### Console Print Full

`console.print_full(delay, interval, ...)`

> [!NOTE] > `console.print_full` offers controlled printing capabilities with specified delay and interval parameters. It is particularly useful for tracking values over time, without cluttering the console with rapid outputs.
>
> **Parameters:**
>
> - `delay`: Time in seconds before the initial print.
> - `interval`: Time in seconds between subsequent prints.
> - `...`: Various data elements to be printed.
>
> **Example:**
>
> ```lua
> console.print_full(2.0, 1.0, "hi", 323232, 55.0, "apple")
> ```
>
> Commences printing 2 seconds after invocation, following with repetitive prints of `hi 323232 55.0 apple` every 1 second.

> [!TIP]
> Console Toggle Keybind: `F1`

### Code Examples:

```lua
on_update(function()
    for _, actor in ipairs(actors_manager.get_all_actors()) do
        console.print("Actor ID: ", actor:get_id());
     end;
end);
```

---

# **Enums**

## Overview

Enums are a handy way to make your code cleaner and more understandable. They're like a set of signposts, guiding you through various options and settings with clear, meaningful names instead of just numbers or arbitrary values.

### Button Click

`button_click`
Enum representing different types of button clicks, often used in conjunction with [button callbacks](https://github.com/qqtnn/diablo_lua_documentation/wiki/Callbacks).

- `lmb`: Left mouse button click.
- `rmb`: Right mouse button click.
- `none`: No button click.

> [!NOTE]
> Useful for handling different mouse interactions, particularly in key press and release scenarios.
> **Example**: `local click_type = button_click.lmb`

### Spell Geometry

`spell_geometry`
Defines the shape of a spell's area, aligning with [`spell_data`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Spell-Data).

- `rectangular`
- `circular`

> [!NOTE]
> Helps specify the geometric area of a spell's effect, whether it's a wide rectangle or a spreading circle.

### Targeting Type

`targeting_type`
Details the targeting mechanism of spells, also found in [`spell_data`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Spell-Data).

- `skillshot`
- `targeted`

> [!NOTE]
> Differentiates between direct targeting spells and skillshots that require precise aiming or prediction.

### Orbwalker Mode

`orb_mode`
Enumerates the various modes of an orbwalker, as utilized in the [Orbwalker module](https://github.com/qqtnn/diablo_lua_documentation/wiki/Orbwalker).

- `none`: No specific mode.
- `pvp`: Player versus player combat mode.
- `clear`: Clearing waves or camps.
- `flee`: Escaping or avoiding combat.

> [!NOTE]
> Essential for defining the behavior of the orbwalker, guiding how your character moves and attacks in different scenarios.

---

# **Game Object**

### get_id

`get_id()` -> `number (int)`

> [!NOTE]
> Returns the unique identifier of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_secondary_data_id

`get_secondary_data_id()` -> `number (int)`

> [!NOTE]
> Returns the secondary data identifier of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_type_id

`get_type_id()` -> `number (int)`

> [!NOTE]
> Provides the type identifier of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_position

`get_position()` -> [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3)

> [!NOTE]
> Retrieves the current position of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) as a [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3).

> [!TIP]
> Use on_render() from [callbacks](https://github.com/qqtnn/diablo_lua_documentation/wiki/Callbacks)
>
> Use get_player_position() to get local player [vec3](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) position from > [global_functions](https://github.com/qqtnn/diablo_lua_documentation/wiki/Global-Functions#get-player-position)
>
> Use actors_manager.get_enemy_npcs() to get a list of enemies [game_object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) > > from [Actors Manager](https://github.com/qqtnn/diablo_lua_documentation/wiki/Actors-Manager#get-enemy-npcs)
>
> Use graphics.circle_3d() from [Graphics](https://github.com/qqtnn/diablo_lua_documentation/wiki/Graphics#draw-3d-circle)

```lua
local color_white = color.new(255,255,255,255);
on_render(function ()

    local player_position = get_player_position();
    local enemies = actors_manager.get_enemy_npcs();

    for i, obj in ipairs(enemies) do
      local position = obj:get_position();
      local distance = position:dist_to(player_position);
      local is_close = distance < 8.0;
        if not is_close then
            goto continue;
            -- when the enemy distance more than 8 units skip
        end;

        graphics.circle_3d(position, 2, color_white);
        -- draw white circle at all enemies position under 8 units of distance
        ::continue::
    end;

end);
```

### is_moving

`is_moving()` -> `bool`

> [!NOTE]
> Indicates whether the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is currently moving.

### is_dashing

`is_dashing()` -> `bool`

> [!NOTE]
> Checks if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is performing a dash action.

### get_active_spell_id

`get_active_spell_id()` -> `number (int)`

> [!NOTE]
> Returns the identifier of the currently active spell of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_active_spell_origin

`get_active_spell_origin()` -> [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3)

> [!NOTE]
> Retrieves the origin of the current active spell as a [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) for the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_active_spell_destination

`get_active_spell_destination()` -> [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3)

> [!NOTE]
> Retrieves the destionation of the current active spell as a [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) for the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_move_destination

`get_move_destination()` -> [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3)

> [!NOTE]
> Retrieves the destination of the current move action as a [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) for the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_dash_destination

`get_dash_destination()` -> [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3)

> [!NOTE]
> Provides the destination of the current dash as a [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) for the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_direction

`get_direction()` -> [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3)

> [!NOTE]
> Retrieves the current direction of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) as a [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3).

### get_current_speed

`get_current_speed()` -> `number (float)`

> [!NOTE]
> Retrieves the current speed of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_total_movement_speed

`get_total_movement_speed()` -> `number (float)`

> [!NOTE]
> Retrieves the total movement speed of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object), combining base speed and any multipliers.

### get_base_movement_speed

`get_base_movement_speed()` -> `number (float)`

> [!NOTE]
> Retrieves the base movement speed of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object), excluding any multipliers.

### get_movement_speed_multiplier

`get_movement_speed_multiplier()` -> `number (float)`

> [!NOTE]
> Retrieves the movement speed multiplier of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object), indicating the factor by which the base speed is modified.

### get_skin_name

`get_skin_name()` -> `string`

> [!NOTE]
> Returns the name of the current skin of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_type

`get_type()` -> `number (int)`

> [!NOTE]
> Provides the type of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### is_basic_particle

`is_basic_particle()` -> `bool`

> [!NOTE]
> Checks if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is a basic particle.

### is_elite

`is_elite()` -> `bool`

> [!NOTE]
> Indicates whether the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is classified as elite.

### is_champion

`is_champion()` -> `bool`

> [!NOTE]
> Determines if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is a champion.

### is_minion

`is_minion()` -> `bool`

> [!NOTE]
> Checks if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is a minion.

### is_boss

`is_boss()` -> `bool`

> [!NOTE]
> Indicates whether the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is a boss.

### is_immune

`is_immune()` -> `bool`

> [!NOTE]
> Checks if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is currently immune.

### is_vulnerable

`is_vulnerable()` -> `bool`

> [!NOTE]
> Determines if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is vulnerable.

### is_untargetable

`is_untargetable()` -> `bool`

> [!NOTE]
> Checks if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is untargetable.

### is_item

`is_item()` -> `bool`

> [!NOTE]
> Indicates whether the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is an item.

### is_interactable

`is_interactable()` -> `bool`

> [!NOTE]
> Determines if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) can be interacted / used.

### get_interact_spell_id

`get_interact_spell_id()` -> `int`

### get_base_health

`get_base_health()` -> `number (float)`

> [!NOTE]
> Returns the base health of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_bonus_health_modifier

`get_bonus_health_modifier()` -> `number (float)`

> [!NOTE]
> Provides the bonus health modifier of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_current_health

`get_current_health()` -> `number (float)`

> [!NOTE]
> Retrieves the current health value of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_max_health

`get_max_health()` -> `number (float)`

> [!NOTE]
> Returns the maximum health value of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

> [!TIP]
> Use get_local_player() to get local player from [Global Functions](https://github.com/qqtnn/diablo_lua_documentation/wiki/Global-Functions#get-local-player)

```lua
local local_player = get_local_player();
local max_health = local_player:get_max_health();
local current_health = local_player:get_current_health();
local current_health_percentage = current_health  / current_health;

if current_health_percentage  < 0.50 then
    -- run code to use potion under 50% health
end
```

### get_base_attack_speed

`get_base_attack_speed()` -> `number (float)`

> [!NOTE]
> Returns the base attack speed of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_bonus_attack_speed

`get_bonus_attack_speed()` -> `number (float)`

> [!NOTE]
> Provides the bonus attack speed added to the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_weapon_damage

`get_weapon_damage()` -> `number (float)`

> [!NOTE]
> Retrieves the weapon damage of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_level

`get_level()` -> `number (int)`

> [!NOTE]
> Provides the current level of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_current_experience

`get_current_experience()` -> `number (int)`

> [!NOTE]
> Retrieves the current experience points of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_experience_total_next_level

`get_experience_total_next_level()` -> `number (int)`

> [!NOTE]
> Returns the total experience needed for the next level for the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_experience_remaining_next_level

`get_experience_remaining_next_level()` -> `number (int)`

> [!NOTE]
> Indicates the remaining experience needed for the next level for the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_character_class_id

`get_character_class_id()` -> `number (int)`

> [!NOTE]
> Provides the character class ID of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

| Class Name  | ID  |
| ----------- | --- |
| Sorcerer    | 0   |
| Barbarian   | 1   |
| Unknown     | 2   |
| Rogue       | 3   |
| Unknown     | 4   |
| Druid       | 5   |
| Necromancer | 6   |

> [!TIP]
> Use get_local_player() to get local player from [Global Functions](https://github.com/qqtnn/diablo_lua_documentation/wiki/Global-Functions#get-local-player)

```lua
local local_player = get_local_player();
if not local_player then
     return; -- prevent accesing nil object
end;

local character_id = local_player:get_character_class_id();
local is_druid = character_id == 5;
if not is_druid then
     return; -- prevent loading plugin from another class
end;

-- this could be used at the beginning of a druid plugin so it doesnt get load unless local player is druid class
```

### get_health_potion_max_count

`get_health_potion_max_count()` -> `number (int)`

> [!NOTE]
> Returns the maximum count of health potions the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) can hold.

### get_health_potion_count

`get_health_potion_count()` -> `number (int)`

> [!NOTE]
> Indicates the current count of health potions held by the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_health_potion_tier

`get_health_potion_tier()` -> `number (int)`

> [!NOTE]
> Returns the tier of health potions held by the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

> [!TIP]
> Use get_local_player() to get local player from [Global Functions](https://github.com/qqtnn/diablo_lua_documentation/wiki/Global-Functions#get-local-player)

```lua
local local_player = get_local_player();

-- warning: local_player could be nil
local max_potions = local_player:get_health_potion_max_count();
local current_potions_amount = local_player:get_health_potion_count();
local is_potion_stash_full = current_potions_amount >= max_potions;

if not is_potion_stash_full then
    -- run code to draw some highlight on potions position around local_player:get_position()
end
```

### get_primary_resource_current

`get_primary_resource_current()` -> `number (int)`

> [!NOTE]
> Retrieves the current primary resource value of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_primary_resource_max

`get_primary_resource_max()` -> `number (int)`

> [!NOTE]
> Provides the maximum value of the primary resource of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_class_specialization_id

`get_class_specialization_id()` -> `number (int)`

> [!NOTE]
> Provides the specialization id of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_rogue_combo_points

`get_rogue_combo_points()` -> `number (int)`

> [!NOTE]
> Returns the amount of combo points of the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### is_dead

`is_dead()` -> `bool`

> [!NOTE]
> Checks if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is currently dead.

### is_enemy

`is_enemy()` -> `bool`

> [!NOTE]
> Determines if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is an enemy.

### is_enemy_with

`is_enemy_with(other)` -> `bool`

- `other`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - Another game object to compare with.
  > [!NOTE]
  > Checks if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) is an enemy of another specified game object.

### get_debug_int

`get_debug_int()` -> `number (int)`

> [!NOTE]
> Retrieves a debug integer value from the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_debug_int_2

`get_debug_int_2()` -> `number (int)`

> [!NOTE]
> Retrieves a second debug integer value from the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_debug_float

`get_debug_float()` -> `number (float)`

> [!NOTE]
> Retrieves a debug float value from the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_buffs

`get_buffs()` -> `table of [buff]`

> [!NOTE]
> Retrieves a table containing all the buffs currently applied to the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object). Each entry in the table is a `buff` object.

### Buff

The `buff` structure represents a buff applied to a game object. It contains the following fields and methods:

- `instance`: Number (Int) - The instance identifier of the buff.
- `type`: Number (Int) - The type identifier of the buff.
- `name_hash`: Number (Int) - The hash value of the buff's name.
- `start_tick`: Number (Int)
- `duration`: Number (Int)
- `flags`: Number (Int)
- `name`: `get_name()` -> `string` - Returns the name of the buff.
- `get_end_time`: `get_end_time()` -> `Number (float)` - Retrieves the end time of the buff.
- `get_remaining_time`: `get_remaining_time()` -> `Number (float)`
- `get_duration`: `get_duration()` -> `Number (float)`
- `is_active_buff`: `is_active_buff()` -> `Boolean`

```lua
local local_player = get_local_player();
local buffs = local_player:get_buffs();

for _, buff in ipairs(buffs) do
    local buff_name = buff:name();
    console.print("Buff Name: " .. buff_name);
end

-- This example demonstrates how to retrieve and print the names of all buffs currently applied to the local player.
```

### get_inventory_items

`get_inventory_items()` -> `table of [item_data]`

> [!NOTE]
> Retrieves a table of item data for all items in the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)'s inventory.

### get_item_count

`get_item_count()` -> `number (int)`

> [!NOTE]
> Returns the count of items in the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)'s inventory.

### get_consumable_count

`get_consumable_count()` -> `number (int)`

> [!NOTE]
> Retrieves the count of consumable items in the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)'s inventory.

### get_quest_item_count

`get_quest_item_count()` -> `number (int)`

> [!NOTE]
> Returns the count of quest-related items in the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)'s inventory.

### get_aspect_count

`get_aspect_count()` -> `number (int)`

> [!NOTE]
> Provides the count of aspects (special items or effects) associated with the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_item_ids_for_bag

`get_item_ids_for_bag(bag_id)` -> `table of number (int)`

- `bag_id`: Number (Int) - The identifier of the bag.
  > [!NOTE]
  > Returns a table of item IDs for a specified bag in the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)'s inventory.

### get_inventory_item_secondary_ids

`get_inventory_item_secondary_ids()` -> `table of number (int)`

> [!NOTE]
> Retrieves a table of secondary IDs for items in the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)'s inventory.

### get_consumables_ids

`get_consumables_ids()` -> `table of number (int)`

> [!NOTE]
> Returns a table of IDs for consumable items in the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)'s inventory.

### get_consumables_names

`get_consumables_names()` -> `table of string`

> [!NOTE]
> Retrieves a table of names for consumable items in the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)'s inventory.

### is_spell_ready

`is_spell_ready(spell_id)` -> `bool`

- `spell_id`: Number (Int) - The identifier of the spell to check.
  > [!NOTE]
  > Checks if a specified spell is ready to be cast by the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### has_enough_resources_for_spell

`has_enough_resources_for_spell(spell_id)` -> `bool`

- `spell_id`: Number (Int) - The identifier of the spell to check.
  > [!NOTE]
  > Determines if the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) has enough resources to cast a specified spell.

### get_equipped_items

`get_equipped_items()` -> `table of [item_data]`

> [!NOTE]
> Returns a table of `item_data` for items equipped by the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object).

### get_inventory_items

`get_inventory_items()` -> `table of [item_data]`

> [!NOTE]
> Retrieves a table of `item_data` for items in the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)'s inventory.

### get_consumable_items

`get_consumable_items()` -> `table of [item_data]`

> [!NOTE]
> Returns a table of `item_data` for consumable items in the [game object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)'s inventory.

### get_stash_items

`get_stash_items()` -> `table of [item_data]`

### get_dungeon_key_items

`get_dungeon_key_items()` -> `table of [item_data]`

### get_socketable_items

`get_socketable_items()` -> `table of [item_data]`

### get_item_info

`get_item_info(item_id)` -> `item_data`

- `item_id`: Number (Int) - The identifier of the item.
  > [!NOTE]
  > Provides `item_data` for a specific item identified by `item_id`.

---

# **Item Data and Affixes**

## Item Rarity Enumeration

An enumeration representing different item rarity levels:

- `normal`
- `magic`
- `magic_2`
- `rare`
- `rare_2`
- `legendary`
- `unique`
- `set`

## Item Data Affix Structure

The `item_data_affix` structure provides detailed information about an item's affix:

- `affix_name_hash`: Number (Int) - The hash value of the affix's name also known as the sno id.
- `balance_offset`: Number (Int) - The balance offset of the affix.
- `get_roll`: `get_roll()` -> `number (float)` - Returns the roll value of the affix.
- `get_roll_min`: `get_roll_min()` -> `number (float)` - Returns the minimum roll value.
- `get_roll_max`: `get_roll_max()` -> `number (float)` - Returns the maximum roll value.
- `get_name`: `get_name()` -> `string` - Retrieves the name of the affix.
- `get_rarity_type`: `get_rarity_type()` -> `number (int)` - Provides the rarity type of the affix.
- `get_affix_data`: `get_affix_data()` -> `userdata` - Accesses internal affix data (for advanced use).
- `get_affix_seed`: `get_affix_seed()` -> `number (int64)` - Returns the seed value used for the affix.

## Item Data Structure

The `item_data` structure represents detailed information about an item:

- `get_skin_name`: `get_skin_name()` -> `string` - Retrieves the skin name of the item.
- `get_name`: `get_name()` -> `string` - Provides the name of the item.
- `get_display_name`: `get_name()` -> `string` - Provides the display name of the item.
- `is_sacred`: `is_sacred()` -> `bool` - Indicates if the item is sacred.
- `is_ancestral`: `is_ancestral()` -> `bool` - Checks if the item is ancestral.
- `get_rarity`: `get_rarity()` -> `item_rarity` - Returns the rarity level of the item.
- `is_junk`: `is_junk()` -> `bool` - Determines if the item is classified as junk.
- `is_locked`: `is_locked()` -> `bool` - Indicates if the item is locked.
- `get_affixes`: `get_affixes()` -> `table of [item_data_affix]` - Retrieves a table of affixes associated with the item.
- `get_durability`: `get_durability()` -> `number (float)` - Provides the item's durability value.
- `get_acd`: `get_acd()` -> `userdata` - Accesses internal ACD data (for advanced use).
- `get_sno_id`: `get_sno_id()` -> `number (int)` - Returns the SNO ID of the item.
- `get_balance_offset`: `get_balance_offset()` -> `number (int)` - Provides the balance offset of the item.
- `get_inventory_row`: `get_inventory_row()` -> `number (int)` - Returns the row number in the inventory where the item is located.
- `get_inventory_column`: `get_inventory_column()` -> `number (int)` - Returns the column number in the inventory where the item is located.
- `get_price`: `get_price()` -> `number (int)`
- `get_stack_count`: `get_stack_count()` -> `number (int)`

> [!TIP]
> Some code examples for items

```lua
    local floor_item_list = actors_manager.get_all_items()
    for i, value in ipairs(floor_item_list) do
        if value then -- prevent accesing invalid ptr
            local object_3d_position = value:get_position()
            graphics.text_3d(value:get_skin_name(), object_3d_position, 16.0, color_yellow(255))

            local object_2d_position = graphics.w2s(object_3d_position)
            if object_2d_position then
                local item_data = value:get_item_info()
                if item_data and item_data:is_valid() then -- prevent accesing invalid ptr

                    object_2d_position.y = object_2d_position.y + 16.0
                    graphics.text_2d(item_data:get_display_name(), object_2d_position, 16.0, color_green(255))

                    object_2d_position.y = object_2d_position.y + 16.0
                    graphics.text_2d(item_data:get_name(), object_2d_position, 16.0, color_white(255))

                    -- note: if you never pick up the item, this table will be empty, it gets filled by server once you pick up once
                    for v, affix in ipairs(item_data:get_affixes()) do
                        if affix then -- prevent accesing invalid ptr

                            object_2d_position.y = object_2d_position.y + 16.0
                            graphics.text_2d(affix:get_name(), object_2d_position, 16.0, color_red(255))
                        end
                    end
                end
            end
        end
    end
```

[![Diablo-IV-lwe-N3ubgc-O.png](https://i.postimg.cc/ZYWLDYwv/Diablo-IV-lwe-N3ubgc-O.png)](https://i.postimg.cc/ZYWLDYwv/Diablo-IV-lwe-N3ubgc-O.png)

> [!TIP]
> This example also can be used for inventory items as they are also gameobjects and contains item_data, once they are in your inventory the existance of affix table is guaranteed as long as they have affixes.

```lua
    local local_player = get_local_player()
    if local_player then
        local equipped_items_list = local_player:get_equipped_items() -- items you are using at the moment, useful to check durability of them for example
        local inventory_items = local_player:get_inventory_items() -- all the items on the first tab of your inventory
        local consumable_items = local_player:get_consumable_items() -- all the items on the second tab of your inventory

    end
```

---

# **Vector2 Class**

## Overview

The `vector2` (vec2) class is a fundamental component for representing and manipulating 2D coordinates. It's extensively used for various calculations and graphical representations in the game.

## Vec2 Constructors

### Create New Vector2 Object

`vec2(x, y)`

- `x`: Number - The x-coordinate of the vector.
- `y`: Number - The y-coordinate of the vector.

> [!NOTE]
> Initializes a new `vec2` object with the specified x and y coordinates, essential for 2D spatial operations.

## Vec2 Methods

### X & Y Coordinates

- `.x`: Returns the x-coordinate (Number).
- `.y`: Returns the y-coordinate (Number).

### Check for Zero Vector

`is_zero()` -> Boolean

> Determines if the vector represents a zero vector (both x and y are zero).

### Project to 3D

`project_3d()` -> [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3)

> Projects the 2D vector into a 3D space, creating a `vec3` object.

### Calculate Distance

`distance(other)` -> Number

- `other`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - Another vector to measure distance to.

> Calculates the Euclidean distance to another `vec2`.

### Calculate Squared Distance

`distance_squared(other)` -> Number

- `other`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - The other vector.

> Returns the squared distance to another `vec2`, useful for performance-sensitive calculations.

### Check for Intersection

`intersects()` -> Boolean

> Evaluates if this vector intersects with another object or vector.

### Vector Length

`length()` -> Number

> Computes the length (magnitude) of the vector.

### Dot Product

`dot_product(other)` -> Number

- `other`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - The vector to dot with.

> Calculates the dot product with another `vec2`.

### Get Unit Vector

`get_unit_vector()` -> [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2)

> Returns the normalized unit vector of this vector.

### Calculate Angle

`get_angle(point, origin)` -> Number

- `point`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - The point vector.
- `origin`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - The origin vector.

> Determines the angle to a point from an origin.

### Extend Towards Target

`get_extended(target, dist)` -> [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2)

- `target`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - The target vector.
- `dist`: Number - Distance to extend.

> Extends the vector towards a target by the specified distance.

### Screen to Game Coordinates

`screen_to_coordinate()` -> [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2)

> Converts screen coordinates to corresponding game coordinates.

### Game to Screen Coordinates

`coordinate_to_screen()` -> [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2)

> Translates game coordinates to screen coordinates.

### Rotate Around Origin

`rotate_around(origin, degree)` -> [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2)

- `origin`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - The pivot point for rotation.
- `degree`: Number - The angle in degrees for rotation.

> Rotates this vector around a specified origin by a given degree.

### Check Equality

`equals(other)` -> Boolean

- `other`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - The vector to compare with.

> Evaluates if this vector is equal to another `vec2`.

---

# **Vector3 Class**

## Overview

The `vector3` (vec3) class is essential for representing and manipulating 3D coordinates, widely used in spatial calculations and graphical positioning.

## Vec3 Constructors

### Create New Vector3 Object

`vec3(x, y, z)`

- `x`: Number - The x-coordinate of the vector.
- `y`: Number - The y-coordinate of the vector.
- `z`: Number - The z-coordinate of the vector.

### Copy Vector3 Object

`vec3(other)`

- `other`: `vec3` - Another vec3 object to copy.

> [!NOTE]
> These constructors allow for the creation of vec3 objects either from specific coordinates or as a copy of another vec3, facilitating 3D operations.

## Vec3 Methods

### Get Rotation

`get_rotation()` -> `vec3`

> Calculates and returns the rotation vector corresponding to the direction this vec3 is pointing.

### Normalize Rotation

`normalize_rotation()` -> `vec3`

> Normalizes the rotation component of this vec3, useful in rotational calculations.

### Normalize Vector

`normalize()` -> `vec3`

> Normalizes this vec3, scaling it to a unit vector while maintaining direction.

### X, Y, Z Coordinates

- `x()`: Returns the x-coordinate (Float).
- `y()`: Returns the y-coordinate (Float).
- `z()`: Returns the z-coordinate (Float).

### Equals Ignore Z

`equals_ignore_z(other)` -> Boolean

- `other`: `vec3` - The vector to compare with, ignoring Z coordinates.

> Checks if this vec3 is equal to another vec3, disregarding the Z coordinate.

### Equals Ignore Z with Threshold

`equals_ignore_z_threshold(other, threshold)` -> Boolean

- `other`: `vec3` - The vector to compare with.
- `threshold`: Number - The maximum allowed difference.

> Evaluates if this vec3 is approximately equal to another vec3 within a specified threshold, ignoring Z coordinates.

### Intersects

`intersects(segment_end, point, margin, radius, denominator)` -> Boolean

- `segment_end`: `vec3` - The end point of the line segment.
- `point`: `vec3` - The point to check for intersection.
- `margin`, `radius`, `denominator`: Numbers - Parameters for intersection calculation.

> Determines if a line segment from this vec3 to `segment_end` intersects a point within given margins.

### Is Facing

`is_facing(other)` -> Boolean

- `other`: `vec3` - The vector to check orientation against.

> Returns true if this vec3 is oriented towards the specified vector.

### To String

`to_string()` -> String

> Converts this vec3 to a string representation, displaying its coordinates.

### Randomize XZ

`randomize_xz(margin)`

- `margin`: Number - The range for randomization.

> Randomizes the X and Z coordinates within the specified margin, altering the vector's position.

### Length (2D and 3D)

- `length_2d()`: Calculates the 2D length (ignoring Z coordinate).
- `length_3d()`: Computes the full 3D length of the vector.
- `length_3d_ignore_z()`: Determines the 3D length, excluding Z coordinate.
- `length_3d_squared()`: Calculates the squared 3D length for performance efficiency.

### Distance Calculations

- `dist_to(other)`: Measures the distance to another vec3.
- `dist_to_ignore_z(other)`: Measures distance, ignoring Z coordinates.
- `squared_dist_to(other)`: Calculates the squared distance for efficiency.
- `squared_dist_to_ignore_z(other)`: Squared distance calculation, excluding Z.

> [!TIP]
> These distance methods are useful for determining proximity between points in both 2D and 3D contexts, with options to consider or ignore the Z-axis.

### Rotate Around

`rotate_around(origin, degree)` -> `vec3`

- `origin`: `vec3` - The pivot point for rotation.
- `degree`: Number - The angle in degrees for rotation.

> Rotates this vec3 around a specified origin point by a given degree, altering its orientation.

### Project to 2D

`project_2d()` -> [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2)

> Projects the vec3 onto a 2D plane, typically by ignoring the Y coordinate, and returns a vec2.

### Cross Product

`cross(other)` -> `vec3`

- `other`: `vec3` - The vector to cross with.

> Calculates the cross product with another vec3, yielding a vector perpendicular to both.

### Other Methods

- `get_unit_vector()`: Returns the normalized unit vector.
- `get_extended(target, units)`: Extends towards the target by a specified distance.
- `get_perp_left(origin, factor)`: Calculates the left perpendicular vector.
- `get_perp_right(origin, factor)`: Calculates the right perpendicular vector.
- `lerp(target, coefficient)`: Linear interpolation towards another vec3.
- `get_relative_angle(other)`: Angle relative to another vector.
- `is_nan()`: Checks for NaN values.
- `is_zero()`: Determines if the vector represents zero.
- `get_angle(target, origin)`: Angle to a target from an origin.
- `get_angle_side(target, origin)`: Angle including the side (left/right) relative to an origin.

> [!NOTE]
> The `vec3` class offers a comprehensive set of methods for 3D vector manipulation, pivotal for spatial calculations, movement, and graphical positioning in the Diablo Lua API.

> [!TIP]
> Use `get_player_position()` to get local player [vec3](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) position from [global_functions](https://github.com/qqtnn/diablo_lua_documentation/wiki/Global-Functions#get-player-position)
>
> Use `actors_manager.get_enemy_npcs()` to get a list of enemies [game_object](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) from [Actors Manager](https://github.com/qqtnn/diablo_lua_documentation/wiki/Actors-Manager#get-enemy-npcs)
>
> Use `vec3`:`squared_dist_to_ignore_z`(`vec3`) for performance

```lua
-- Example: Using vec3 in enemy proximity checks
local player_position = get_player_position();
local enemies = actors_manager.get_enemy_npcs();

for _, obj in ipairs(enemies) do
    local enemy_position = obj:get_position();
    -- note squared_dist_to_ignore_z for performance
    local distance_sqr = enemy_position:squared_dist_to_ignore_z(player_position);
    if distance_sqr > (2.0 * 2.0) then
        -- Skip if the enemy is not in melee range
        goto continue;
    end;

    -- Logic for close-range enemy interaction

    ::continue::
end;
```

---

# **Color Class**

## Introduction

The `color` class in Lua scripting provides a way to define and utilize colors in your scripts. This class allows for the creation of color objects with varying degrees of red, green, blue, and alpha (transparency) values.

## Constructors

### Color with RGB

`color(r: number (int), g: number (int), b: number (int))`

> Creates a new `color` object using RGB values.
>
> - `r`: Red component (0-255).
> - `g`: Green component (0-255).
> - `b`: Blue component (0-255).

### Color with RGBA

`color(r: number (int), g: number (int), b: number (int), a: number (int))`

> Creates a new `color` object using RGBA values.
>
> - `r`: Red component (0-255).
> - `g`: Green component (0-255).
> - `b`: Blue component (0-255).
> - `a`: Alpha component (0-255) for transparency.

## Examples

```lua
-- Creating a solid red color
local color_red = color.new(255, 0, 0)

-- Creating a white color with full opacity
local color_white = color.new(255, 255, 255, 255)
```

### Predefined Colors

> In addition to custom colors, the Lua scripting environment for Diablo also provides a variety of predefined colors as global functions. These global color functions are readily accessible and can be customized with an alpha value to control their transparency.

```lua
color_white(alpha);
color_black(alpha);
color_yellow(alpha);
color_red(alpha);
color_green(alpha);
color_blue(alpha);
color_pink(alpha);
color_purple(alpha);
color_grey(alpha);
color_brown(alpha);
color_gold(alpha);
color_silver(alpha);
color_orange(alpha);
color_cyan(alpha);
color_green_pastel(alpha);
color_red_pale(alpha);
color_green_pale(alpha);
color_blue_pale(alpha);
color_cyan_pale(alpha);
color_gray_pale(alpha);
color_gray_clear(alpha);
color_orange_red(alpha);
```

> Each predefined color function accepts an alpha parameter (0-255), allowing you to control the transparency level of the color.

---

# **Graphics Module**

## Overview

The Graphics module provides a versatile set of functions for drawing shapes, text, and images on the screen, enhancing the visual aspects of scripts.

## Functions

### Draw Filled Circle (2D)

`graphics.circle_2d_filled(pos, radius, color)`

- `pos`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - Center position of the circle.
- `radius`: Number - Radius of the circle.
- `color`: [`color`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - Color of the circle.

> [!NOTE]
> This function draws a solid, filled circle in 2D space. Useful for highlighting areas or points on the screen.

### Draw Circle Outline (2D)

`graphics.circle_2d(pos, radius, color, thickness)`

- `pos`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - Center position.
- `radius`: Number - Circle's radius.
- `color`: [`color`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - Outline color.
- `thickness`: Number - Thickness of the outline.

> [!NOTE]
> Creates a 2D circle outline. Ideal for marking areas without obscuring underlying details.

### Draw Circle Outline at 3D Position

`graphics.circle_2d(pos, radius, color)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - 3D center position.

> [!NOTE]
> Renders a 2D circle outline based on a 3D position. Useful for visualizing areas around objects or locations in the game world.

### Render 3D Text

`graphics.text_3d(text, pos, size, color)`

- `text`: String - The text to display.
- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - Position for the text.
- `size`: Number - Font size.
- `color`: [`color`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - Text color.

> [!NOTE]
> This function allows displaying text in a 3D space, which can float above game objects or specific locations.
> **Example**: `graphics.text_3d("Hello World", get_player_position(), 15, color_white(255))`

```lua
on_render(function()
    local player_position = get_player_position();
    local enemies_list = actors_manager.get_enemy_npcs();

    -- sorting actors by distance to the local player
    table.sort( enemies_list, function(a, b)
        return a:get_position():squared_dist_to_ignore_z(player_position) <
         b:get_position():squared_dist_to_ignore_z(player_position)
    end);

    for i, obj in ipairs(enemies_list) do
        local obj_position = obj:get_position();
        local distance_sqr = obj_position:squared_dist_to_ignore_z(player_position);

        if distance_sqr < (14.0 * 14.0) then
            graphics.text_3d(tostring(i) .. ": " .. obj:get_skin_name(),
            obj_position, 20, color_white(255));
        end
    end
end);
```

![](https://aimsharp.net/wp-content/uploads/2023/12/d1.jpg)

### Draw Line

`graphics.line(from, to, color, thickness)`

- `from`, `to`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - Start and end points.
- `color`: [`color`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - Line color.
- `thickness`: Number - Line thickness.

> Alternative from and to can be vec3

> [!NOTE]
> Useful for connecting two points with a visible line, aiding in mapping paths or connections between elements.

### Draw Rectangle Outline

`graphics.rect(from, to, color, rounding, thickness)`

- `from`, `to`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - Corner points of the rectangle.
- `color`: [`color`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - Outline color.
- `rounding`: number (float)
- `thickness`: number (float)

> [!NOTE]
> Outlines a rectangular area on the screen, perfect for framing sections or creating boundaries.

### Draw Filled Rectangle

`graphics.rect_filled(from, to, color)`

- `from`, `to`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - Corner points.
- `color`: [`color`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - Fill color.

> [!NOTE]
> Fills a specified rectangular area with color. Great for background elements or highlighting zones.

```lua
on_render(function()
    local local_player = get_local_player();
    if not local_player then
        return;
    end

    local maxt_health = local_player:get_max_health();
    local current_health = local_player:get_current_health();
    local health_percentage = current_health / maxt_health;

    local player_position = local_player:get_position();
    local player_position_2d = graphics.w2s(player_position);
    if player_position_2d:is_zero() then
        return;
    end

    -- copy player_position_2d vec2 to avoid reference
    local health_bar_position =  vec2.new(player_position_2d.x, player_position_2d.y);
    health_bar_position.y = health_bar_position.y - 125;

    local start_point = vec2.new(health_bar_position.x, health_bar_position.y);
    start_point.x = start_point.x - 75;

    local end_point = vec2.new(health_bar_position.x, health_bar_position.y);
    end_point.x = end_point.x + 75;
    end_point.y = end_point.y - 13;

    local end_height = end_point.y;

    -- background
    graphics.rect_filled(start_point, end_point, color_black(200))

    -- healthbar %
    local distance = start_point:distance(end_point);
    local health_bar_end = start_point:get_extended(end_point, distance * health_percentage);
    health_bar_end.y = end_height;
    graphics.rect_filled(start_point, health_bar_end, color_green(150));
end);
```

![](https://aimsharp.net/wp-content/uploads/2023/12/d2.jpg)

### Load Image

`graphics.load_image(path_to_asset)`

- `path_to_asset`: String - Path to the image file.

> [!NOTE]
> Loads an image from the specified file path, preparing it for rendering in the game environment.

### Draw Image

`graphics.draw_image(image, pos)`

- `image`: Loaded image object.
- `pos`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - Position to place the image.

> [!NOTE]
> Renders a previously loaded image at a specified position. Ideal for adding custom visuals or icons.

### World to Screen

`graphics.w2s(start_position)`

- `start_position`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - 3D world position.

> [!NOTE]
> Converts a 3D world position to a 2D screen position, bridging the gap between game world and screen space.

### Draw 3D Circle

`graphics.circle_3d(pos, radius, color)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - Center position in 3D space.
- `radius`: Number - Circle's radius.
- `color`: [`color`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - Circle color.

> [!NOTE]
> Draws a circle that appears in 3D space, useful for encircling objects or points of interest.

### Render Text

`graphics.l_text(text, pos, size, color)`

- `text`: String - Text content.
- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - Text position in 3D.
- `size`: Number - Font size.
- `color`: [`color`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - Text color.

> Alternative graphics.l_text_2d(text, pos, size, color)

> [!NOTE]
> This function is designed for displaying large, noticeable text in a 3D environment.

### Draw 3D Rectangle

`graphics.rect_3d(from, to, width, color, thickness)`

- `from`, `to`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - 3D start and end points.
- `width`: Number - Rectangle width.
- `color`: [`color`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - Rectangle color.
- `thickness`: Number - Outline thickness.

> [!NOTE]
> Creates a 3D rectangular shape, extending between two points in space. Effective for visualizing areas or paths in the game world.

---

# **Menu Elements**

## Overview

Menu Elements are essential for creating interactive and user-friendly interfaces in the game's menu. Each type of menu element has unique functionalities, enhancing the user experience.

## Button

### Constructor

- `button:new(id)`: Creates a new button instance.

### Description

Adds an interactive button to the menu interface.

### Methods

- `render(button_name, tooltip, activation_delay, click_type)`: Displays the button.
  - `button_name`: String - The text displayed on the button.
  - `tooltip`: String - A helpful hint displayed when hovering over the button.
  - `activation_delay`: Number - Delay before the button becomes active after rendering.
  - `click_type`: `button_click` - The type of click interaction (left, right, none).
- `get()`: Returns the button's current state (clicked/not clicked).
- `set_id(number)`: Sets a unique identifier for the button.
  - `number`: Integer - The unique ID for the button.
- `get_full()`: Retrieves detailed information about the button's state and properties.

> [!NOTE]
> Buttons are fundamental for triggering actions and navigating menus. The unique ID (`id`) is crucial for distinguishing different buttons.

## Checkbox

### Constructor

- `checkbox:new(default_state, id)`: Initializes a new checkbox.

### Description

Introduces a checkbox element for toggling options on and off.

### Methods

- `render(label, tooltip)`: Renders the checkbox.
  - `label`: String - The text label next to the checkbox.
  - `tooltip`: String - Additional information displayed on hover.
- `get()`: Retrieves the current state (checked/unchecked) of the checkbox.
- `set(value)`: Sets the checkbox to a specific state.
  - `value`: Boolean - The desired state of the checkbox (true for checked).

> [!NOTE]
> Checkboxes are ideal for enabling or disabling features and settings within the menu.

## Combo Box

### Constructor

- `combo_box:new(default_state, id)`: Establishes a new combo box.

### Description

Creates a dropdown menu with multiple selectable options.

### Methods

- `render(label, items, tooltip)`: Shows the combo box.
  - `label`: String - The title of the combo box.
  - `items`: Table - A list of options available in the dropdown.
  - `tooltip`: String - A brief description or guide.
- `get()`: Returns the index of the currently selected item.
- `set(value)`: Selects an item based on its index.
  - `value`: Integer - The index of the item to select.

> [!WARNING]
> Ensure each combo box has a unique ID to prevent conflicts with other menu elements.

## Input Text

### Constructor

- `input_text:new(id)`: Generates a new input text field.

### Description

Adds a field for entering text.

### Methods

- `render(label, tooltip, require_button, button_label, button_tooltip)`: Displays the input text field.
  - `label`: String - The title of the input field.
  - `tooltip`: String - Extra information for users.
  - `require_button`: Boolean - Determines if a button is needed to submit text.
  - `button_label`: String - Text for the submission button.
  - `button_tooltip`: String - Tooltip for the submission button.
- `get()`: Retrieves the text entered in the field.
- `get_in_vec3()`: Converts and returns the input text as a `vec3` object, if possible.
- `is_open()`: Checks if the input field is currently active.

> [!NOTE]
> Input Text fields are versatile for user inputs, from simple text entries to coordinates and numerical values.

## Slider (Int and Float)

### Constructors

- `slider_int:new(min_value, max_value, default_value, id)`: Sets up an integer slider.
- `slider_float:new(min_value, max_value, default_value, id, rounding)`: Initializes a floating-point slider.

### Description

These sliders allow users to select a value within a specified range.

### Methods

- `render(label, tooltip, rounding)`: Displays the slider.
  - `label`: String - The title of the slider.
  - `tooltip`: String - Additional details about the slider's purpose.
  - `rounding`: Integer (only for `slider_float`) - Rounding precision for floating-point values.
- `get()`: Returns the current value selected on the slider.

> [!TIP]
> Sliders are useful for settings that require precision, like adjusting volumes or scaling factors.

## Tree Node

### Constructor

- `tree_node:new(node_depth)`: Creates a new section in the menu.

### Description

Facilitates the creation of structured, hierarchical menu sections.

### Example:

- Main section: `local main_section = tree_node:new(0)`
- Sub-section: `local sub_section = tree_node:new(1)`

## Keybind

### Constructor

- `keybind(int, bool, uint32_t)`: Establishes a keybind element.

### Description

Allows users to set custom keybindings for various actions.

### Methods

- `render(label, tooltip)`: Renders the keybind setting.
  - `label`: String - The description of the keybind.
  - `tooltip`: String - Guidance on setting the keybind.
- `get_state()`: Returns the current state of the keybind (active/inactive).
- `get_key()`: Retrieves the key currently bound.
- `set(key, toggle, mode)`: Configures the keybind.
  - `key`: Integer - The keycode to bind.
  - `toggle`: Boolean - If true, the keybind acts as a toggle.
  - `mode`: Integer - The mode of the keybind.

> [!TIP]
> Keybinds allow for customizable control schemes and shortcuts.

```lua
local developer_id = "rename_me"
local feature_keybind= keybind:new(0x01, false, get_hash(developer_id  .. "mode_selector_placeholder_id"));

-- somewhere else
if feature_keybind:get_state() then
    -- Logic for activated feature
end
```

> [!TIP]
> Keybinds second parameter boolean is to indicate is_toggle

## Color Picker

### Constructor

- `colorpicker:new(id, default_color)`: Creates a new color picker.

```lua
local menu_elements = {
    color_example = colorpicker:new(get_hash("dev_label_" .. "color_example_unique_id"), ImVec4:new(255,255,0,255))
}

-- to access the color menu element
local color = menu_elements.color_example:get();

-- to render color in menu
menu_elements.color_example:render("Color Picker", "Tooltip");
```

### Description

Provides a tool for selecting and customizing colors.

### Methods

- `render(label, tooltip, show_on_button_press, button_label, button_tooltip)`: Displays the color picker.
  - `label`: String - The title of the color picker.
  - `tooltip`: String - Extra information about the color picker.
  - `show_on_button_press`: Boolean - Determines if the picker is shown on button press.
  - `button_label`: String - The label for the button.
  - `button_tooltip`: String - Tooltip for the button.
- `get()`: Retrieves the currently selected color.
- `set(color)`: Sets the color picker to a specific color.
  - `color`: `ImColor` - The color to set.

---

# **Actors Manager**

## Overview

The Actors Manager component, is an easy way to get list of objects already pre-filtered in the core.

## Functions

### Get All Actors

`actors_manager.get_all_actors()`

> [!NOTE]
> Returns a table with all actors in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

```lua
local actors = actors_manager.get_all_actors()

-- sorting actors by distance to the local player
local player_position = get_player_position()
table.sort(actors, function(a, b)
    return a:get_position():squared_dist_to_ignore_z(player_position) <
     b:get_position():squared_dist_to_ignore_z(player_position)
end);

-- now interact with the actors in order of proximity
for _, actor in ipairs(actors) do
    if actor:is_enemy() and actor:is_alive() then
        -- Process only living enemies
        -- Add your logic here
    end
end
```

### Get Enemy Actors

`actors_manager.get_enemy_actors()`

> [!NOTE]
> Returns a table with all enemy actors in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Ally Actors

`actors_manager.get_ally_actors()`

> [!NOTE]
> Returns a table with all ally actors in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get All Particles

`actors_manager.get_all_particles()`

> [!NOTE]
> Returns a table with all particles in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Ally Particles

`actors_manager.get_ally_particles()`

> [!NOTE]
> Returns a table with all ally particles in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Enemy Particles

`actors_manager.get_enemy_particles()`

> [!NOTE]
> Returns a table with all enemy particles in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get All Players

`actors_manager.get_all_players()`

> [!NOTE]
> Returns a table with all players in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Ally Players

`actors_manager.get_ally_players()`

> [!NOTE]
> Returns a table with all ally players in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Enemy Players

`actors_manager.get_enemy_players()`

> [!NOTE]
> Returns a table with all enemy players in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get All NPCs

`actors_manager.get_all_npcs()`

> [!NOTE]
> Returns a table with all npc in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Ally NPCs

`actors_manager.get_ally_npcs()`

> [!NOTE]
> Returns a table with all ally npc in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Enemy NPCs

`actors_manager.get_enemy_npcs()`

> [!NOTE]
> Fetches data on enemy NPCs, organizing it in a table format.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get All Items

`actors_manager.get_all_items()`

> [!NOTE]
> Returns a table with all items in game memory.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

---

# **Target Selector**

## Overview

The Target Selector module offers a variety of functions for selecting targets based on specific criteria, enabling more strategic gameplay decision making.

### Data Types

#### `area_result`

- Constructor: `area_result()`
- Contains:
  - `.main_target`: Reference to a [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)
  - `.victim_list`: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)
  - `.n_hits`: Number of hits (int)
  - `.score`: Scoring value of the target area (float)

#### `area_result_light`

- Constructor: `area_result_light()`
- Contains:
  - `.main_target`: Reference to a [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)
  - `.n_hits`: Number of hits (int)
  - `.score`: Scoring value of the target area (float)

## Functions

### Is Valid Enemy

`target_selector.is_valid_enemy(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The object to check.

> [!NOTE]
> Determines if the provided game object is a valid enemy target.
>
> - Returns: `bool`

### Get PvP Target

`target_selector.get_pvp_target(source, dist)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `dist`: Distance in units to search for the target.

> [!NOTE]
> Retrieves the most suitable target for PvP within the specified distance from the source.
>
> - Returns: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Closest Target

`target_selector.get_target_closer(source, dist)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `dist`: Distance in units to search for the target.

> [!NOTE]
> Finds the nearest target within the given distance from the source.
>
> - Returns: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Least HP Target

`target_selector.get_target_low_hp(source, dist)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `dist`: Distance in units to search for the target.

> [!NOTE]
> Selects the target within range that has the lowest health.
>
> - Returns: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Most HP Target

`target_selector.get_target_most_hp(source, dist)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `dist`: Distance in units to search for the target.

> [!NOTE]
> Chooses the target within range that has the highest health.
>
> - Returns: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Get Target in Circular Area

`target_selector.get_target_area_circle(source, dist, radius, min_hits)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `radius`: Radius in units of the circular area.
- `min_hits`: Minimum number of targets required in the area (int).

> [!NOTE]
> Identifies the optimal target within a specified circular area, based on the minimum hits criteria.
>
> - Returns: `area_result` object

### Get Most Hits in Rectangle - Light

`target_selector.get_most_hits_target_rectangle_area_light(source, rect_length, rect_width, prio_champion)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `rect_length`: Length in units of the rectangular area.
- `rect_width`: Width in units of the rectangular area.
- `prio_champion`: Boolean indicating whether to prioritize champions.

> [!NOTE]
> Finds the target in a rectangular area that maximizes the hit count, with an option to prioritize champions.
>
> - Returns: `area_result_light` object

### Get Most Hits in Circle - Light

`target_selector.get_most_hits_target_circular_area_light(source, dist, radius, prio_champions)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `dist`: Distance in units to search for targets.
- `radius`: Radius in units of the circular area.
- `prio_champions`: Boolean indicating whether to prioritize champions.

> [!NOTE]
> Selects the target in a circular area that maximizes hit count, with an option to prioritize champions.
>
> - Returns: `area_result_light` object

### Get Most Hits in Rectangle - Heavy

`target_selector.get_most_hits_target_rectangle_area_heavy(source, rect_length, rect_width)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `rect_length`: Length in units of the rectangular area.
- `rect_width`: Width in units of the rectangular area.

> [!NOTE]
> Identifies the best target in a rectangular area based on the maximum number of hits possible.
>
> - Returns: `area_result` object

### Get Most Hits in Circle - Heavy

`target_selector.get_most_hits_target_circular_area_heavy(source, dist, radius)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `dist`: Distance in units to search for targets.
- `radius`: Radius in units of the circular area.

> [!NOTE]
> Determines the optimal target in a circular area based on the maximum number of hits possible.
>
> - Returns: `area_result` object

```lua
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

local function get_best_point(target_position, width, current_hits)
    local radius = width * 0.5;
    local points = generate_points_around_target(target_position, radius * 0.75, 8); -- Generate 8 points around target
    local hit_table = {};

    for _, point in ipairs(points) do
        local hits = utility.get_amount_of_units_inside_circle(point, radius);
        table.insert(hit_table, {point = point, hits = hits});
        graphics.circle_3d(point, radius, color_red(100))
    end

    -- sort by the number of hits
    table.sort(hit_table, function(a, b) return a.hits > b.hits end);

    if hit_table[1].hits > current_hits then
        return hit_table[1].point; -- returning the point with the most hits
    end

    return target_position;
end

-- register on_update callback to call the code each frame
on_update(function()

    -- filter the code to work only with orbwalker runing some mode
    if orbwalker.get_orb_mode() == orb_mode.none then
        return;
    end;

    local circle_width = 7.5;
    local circle_radius = circle_width * 0.5;
    local player_position = get_player_position();
    local area_data = target_selector.get_most_hits_target_circular_area_heavy(player_position, 10.0, circle_radius)
    local best_target = area_data.main_target;

    if not best_target then
        return;
    end

    local current_hits = area_data.n_hits;
    local best_target_position = best_target:get_position();
    local best_cast_position = get_best_point(best_target_position, circle_width, current_hits);

    local spell_id = 915150;
    if cast_spell.position(spell_id, best_cast_position) then
        console.print("Casted Circle Are Spell Successfully"); -- in the best position where hits most units
        return;
    end
end);
```

> Green circle represents the position where it would cast to hit most of the units

![](https://aimsharp.net/wp-content/uploads/2023/12/d3.jpg)

### Get Nearby Target List

`target_selector.get_near_target_list(source, max_range)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `max_range`: Maximum range in units to include targets.

> [!NOTE]
> Retrieves a list of all potential targets within the specified range from the source.
>
> - Returns: Table of [`gameobjects`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Find Quick Champion

`target_selector.get_quick_champion(source, max_range)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for targeting.
- `max_range`: Maximum range in units to search for the champion.

> [!NOTE]
> Locates the nearest enemy champion within the given range from the source.
>
> - Returns: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object)

### Is Wall Collision

`target_selector.is_wall_collision(source, target, width)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for the check.
- `target`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The target object.
- `width`: Width in units of the path to check for collision.

> [!NOTE]
> Determines if there is a wall collision between the source position and the target along a specified path width.
>
> - Returns: `bool`

### Is Unit Collision

`target_selector.is_unit_collision(source, target, width)`

- `source`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position for the check.
- `target`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The target object.
- `width`: Width in units of the path to check for collision.

> [!NOTE]
> Determines if there is any unit collision between the source position and the target along a specified path width.
>
> - Returns: `bool`

---

# **Orbwalker**

## Overview

The Orbwalker component provides functionalities to get and set the orbwalking mode. It helps in managing the character's movement and attack behavior during gameplay.

## Functions

### Get Orbwalker Mode

`orbwalker.get_orb_mode()`

> [!NOTE]
> Returns the current orbwalker mode.
>
> - Returns: An integer representing the orbwalker mode.

## Enum: orb_mode

The `orb_mode` enum defines the different modes that the orbwalker can be in. These modes determine the behavior of the character in terms of movement and attacking.

### Enum Values

- `none`: Represents no specific orbwalking mode.
- `pvp`: Represents the player vs
- `clear`
- `flee`

### Set Orbwalker Mode

`orbwalker.set_orbwalker_mode(mode)`

```lua
--none = 0,
--pvp = 1,
--flee = 2,
--clear = 3

-- both are the same
orbwalker.set_orbwalker_mode(3)
orbwalker.set_orbwalker_mode(orb_mode.clear)
```

### Set Clear Toggle

`orbwalker.set_clear_toggle(value)` - `value param: boolean`

### Set Block Movement

`orbwalker.set_block_movement(value)` - `value param: boolean`

### Set Auto Loot Toggle

`orbwalker.set_auto_loot_toggle(value)` - `value param: boolean`

---

# **Cast Spell**

## Functions

### Cast Spell on Self

`cast_spell.self(spell_id, animation_time)`

- `spell_id`: Number (Int) - The identifier of the spell to cast.
- `animation_time`: Number (Float) - The animation time of the spell.

> [!NOTE]
> Casts a spell on the caster (self-cast) with specified animation time.
>
> - Returns: `bool`

### Cast Spell on Target

`cast_spell.target(target, spell_id, animation_time, is_debug_mode)`

- `target`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The target object for the spell.
- `spell_id`: Number (Int) - The identifier of the spell to cast.
- `animation_time`: Number (Float) - The animation time of the spell.
- `is_debug_mode`: Bool - Option to enable debug mode.

> [!NOTE]
> Casts a spell towards a specific target with animation time and an optional debug mode.
>
> - Returns: `bool`

#### Alternative with Spell Data

`cast_spell.target(target, spell_data, is_debug_mode)`

- `target`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The target object for the spell.
- `spell_data`: `spell_data` - Detailed data of the spell.
- `is_debug_mode`: Bool - Option to enable debug mode.

> [!NOTE]
> Casts a spell towards a target using detailed spell data, with optional debug mode.
>
> - Returns: `bool`

### Cast Spell on Position

`cast_spell.position(spell_id, position, animation_time)`

- `spell_id`: Number (Int) - The identifier of the spell to cast.
- `position`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The position to cast the spell.
- `animation_time`: Number (Float) - The animation time of the spell.

> [!NOTE]
> Casts a spell on a specified [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) position with given animation time.
>
> - Returns: `bool`

### Add Channel Spell

`cast_spell.add_channel_spell(spell_id, start_time, finish_time, cast_target, cast_position, animation_time, interval)`

- `spell_id`: Number (Int) - The identifier of the spell.
- `start_time`: Number (Float) [Optional] - The start time for the spell. Defaults to current time.
- `finish_time`: Number (Float) [Optional] - The finish time for the spell. Defaults to `0` (undefined).
- `cast_target`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) [Optional] - The target object to cast the spell on.
- `cast_position`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) [Optional] - The position to cast the spell at.
- `animation_time`: Number (Float) [Optional] - The animation time of the spell (will block other actions like movement inputs).
- `interval`: Number (Float) [Optional] - The intervals you want the spell to be casted, by default 0 means spam the spell.

> [!NOTE]  
> Adds a channel spell with specified parameters. Defaults are provided for optional parameters.

### Pause All Channel Spells

`cast_spell.pause_all_channel_spells(pause_duration)`

- `pause_duration`: Number (Float) - The duration to pause all spells in seconds.

> [!NOTE]  
> Pauses all active channel spells for the specified duration.

### Pause Specific Channel Spell

`cast_spell.pause_specific_channel_spell(spell_id, pause_duration)`

- `spell_id`: Number (Int) - The identifier of the spell to pause.
- `pause_duration`: Number (Float) - The duration to pause the spell in seconds.

> [!NOTE]  
> Pauses a specific channel spell by its identifier for the specified duration.

### Check If Channel Spell Is Active

`cast_spell.is_channel_spell_active(spell_id)`

- `spell_id`: Number (Int) - The identifier of the spell to check.

> [!NOTE]  
> Checks if a specific spell is currently active in the channel spell handler.
>
> - Returns: `bool`

### Update Channel Spell Target

`cast_spell.update_channel_spell_target(spell_id, new_target)`

- `spell_id`: Number (Int) - The identifier of the spell to update.
- `new_target`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The new target object for the spell.

> [!NOTE]  
> Updates the target object of a specific channel spell.

### Update Channel Spell Position

`cast_spell.update_channel_spell_position(spell_id, new_position)`

- `spell_id`: Number (Int) - The identifier of the spell to update.
- `new_position`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The new position to cast the spell.

> [!NOTE]  
> Updates the position of a specific channel spell.

### Update Channel Spell Finish Time

`cast_spell.update_channel_spell_finish_time(spell_id, new_finish_time)`

- `spell_id`: Number (Int) - The identifier of the spell to update.
- `new_finish_time`: Number (Float) - The new finish time of the spell.

> [!NOTE]  
> Updates the finish time of a specific channel spell.

### Update Channel Spell Start Time

`cast_spell.update_channel_spell_start_time(spell_id, new_start_time)`

- `spell_id`: Number (Int) - The identifier of the spell to update.
- `new_start_time`: Number (Float) - The new start time of the spell.

> [!NOTE]  
> Updates the start time of a specific channel spell.

### Update Channel Spell Animation Time

`cast_spell.update_channel_spell_animation_time(spell_id, new_animation_time)`

- `spell_id`: Number (Int) - The identifier of the spell to update.
- `new_animation_time`: Number (Float) - The new animation time of the spell.

> [!NOTE]  
> Updates the animation time of a specific channel spell.

### Update Channel Spell Interval

`cast_spell.update_channel_spell_interval(spell_id, new_interval)`

- `spell_id`: Number (Int) - The identifier of the spell to update.
- `new_interval`: Number (Float) - The new interval time of the spell.

> [!NOTE]  
> Updates the interval time of a specific channel spell.

### Remove Channel Spell

`cast_spell.remove_channel_spell(spell_id)`

- `spell_id`: Number (Int) - The identifier of the spell to remove.

> [!NOTE]  
> Removes a specific channel spell by its identifier.

---

# **Spell Data**

The `spell_data` usertype in Lua provides a structured way to handle various attributes of spells in game programming, allowing for detailed configuration and prediction calculations. Below are the properties and constructor parameters available for use.

## Constructor

The `spell_data` constructor allows for creating new spell data instances with specific attributes. It accepts the following parameters:

- **radius**: `float` - The radius of the spell effect.
- **range**: `float` - The maximum range of the spell.
- **cast_delay**: `float` - The delay before the spell is cast, in seconds.
- **projectile_speed**: `float` - The speed of the spell's projectile.
- **has_wall_collision**: `bool` - Indicates whether the spell's projectile can collide with walls.
- **spell_id**: `int32_t` - A unique identifier for the spell.
- **geometry_type**: `prediction::spell_geometry` - The geometric type of the spell, defining its shape and area of effect.
- **targeting_type**: `prediction::targeting_type` - The targeting mechanism type of the spell.

Example of constructing a `spell_data` object:

```lua
local spell_data = spell_data:new(
    3.0,                        -- radius
    9.0,                        -- range
    1.5,                        -- cast_delay
    3.0,                        -- projectile_speed
    true,                       -- has_collision
    spell_id_barrage,           -- spell_id
    spell_geometry.rectangular, -- geometry_type
    targeting_type.skillshot    --targeting_type
)
```

## Properties

Each `spell_data` object offers access to its defined properties, allowing adjustments and real-time updates based on gameplay dynamics:

- **radius**: Manages the operational radius of the spell's effect, adaptable to different gameplay scenarios.
- **range**: Sets the operational range within which the spell can be effectively cast.
- **cast_delay**: Controls the initiation time before the spell's effect begins, crucial for timing strategies in gameplay.
- **projectile_speed**: Determines the travel speed of the spell's projectiles, affecting how quickly they reach their target.
- **has_wall_collision**: Indicates if the spell's projectiles are meant to interact with environmental obstacles.
- **spell_id**: Acts as a unique reference for the spell, important for tracking and differentiating between multiple spells.
- **geometry_type**: Describes the physical shape of the spell's effect area, important for visual and mechanical aspects of the spell.
- **targeting_type**: Details the targeting mechanics of the spell, influencing how it selects and affects targets within the game environment.

This usertype is integral for developers to finely tune the characteristics and behaviors of spells in game development, ensuring that each spell operates according to specific gameplay requirements and strategies.

---

# **Prediction**

## Overview

The Prediction module is essential for enhancing interaction and engagement with moving objects and spells within the game environment. It provides functions and tools for predicting the movement of units and the interaction of spells, allowing for more strategic gameplay.

## Classes and User Types

### `prediction_parameters`

A class that holds parameters used for making predictions about spell casts.

- **Constructors**:
  - `prediction_parameters(vec3, float)`
- **Properties**:
  - `cast_origin`: vec3 - The origin point of the cast.
  - `intersection`: float - The intersection parameter used in calculations.

### `prediction_result_candidates`

A class that stores potential results of prediction calculations.

- **Constructors**:
  - `prediction_result_candidates()`
- **Properties**:
  - `center_position`: vec3 - The center position of the prediction area.
  - `intersection_position`: vec3 - The intersection position within the prediction area.
  - `max_intersection_position`: vec3 - The position with the maximum intersection.

### `prediction_result`

A class encapsulating the results of a prediction.

- **Constructors**:
  - `prediction_result()`
- **Properties**:
  - `hitchance`: float - The chance of hitting the target.
  - `cast_position`: vec3 - The position from which to cast the spell.
  - `time_to_hit`: float - The time it will take for the spell to hit the target.
  - `candidates`: `prediction_result_candidates` - The candidates of prediction results.

## Functions

### Get Prediction Result

`prediction.get_prediction_result(target, params, spell_data, debug_call)`

- Retrieves the prediction result for a given target, spell, and set of parameters.
- `target`: game::object\* - The target object.
- `params`: prediction_parameters - The parameters for the prediction.
- `spell_data`: spell_data - The data regarding the spell.
- `debug_call`: bool - Whether to output debug information.

### Get Future Unit Position

`prediction.get_future_unit_position(unit, time)`

- Predicts the future position of a unit after a specified time.
- `unit`: game::object\* - The unit whose position to predict.
- `time`: float - The time after which to predict the unit's position.

### Get Intersection Position

`prediction.get_intersection_position(origin, center_position, intersection)`

- Calculates the intersection position based on given parameters.
- `origin`: vec3 - The origin point for the calculation.
- `center_position`: vec3 - The central point for the calculation.
- `intersection`: float - The intersection distance.

### Get Cast Position

`prediction.get_cast_position(target, params, spell_data, prediction_result_ptr)`

- Determines the optimal cast position for a spell on a given target.
- `target`: game::object\* - The target of the spell.
- `params`: prediction_parameters - Parameters used for prediction.
- `spell_data`: spell_data - Data about the spell.
- `prediction_result_ptr`: prediction_result\* - Pointer to store the result of the prediction.

### Get Hit Time

`prediction.get_hit_time(source, point, speed, delay, extra_network_time, hitbox, debug_mode)`

- Calculates the time it will take for a hit to occur from the source to the target point.
- `source`: vec3 - The source position.
- `point`: vec3 - The target point.
- `speed`: float - The speed of the projectile or unit.
- `delay`: float - The delay before the projectile or action starts.
- `extra_network_time`: float - Additional network delay to consider.
- `hitbox`: float - The hitbox size of the target.
- `debug_mode`: bool - If true, outputs debug information.

### Get Collisions (Circular and Rectangular)

- `prediction.get_collisions_circular(radius, center)`
  - Determines circular collision points within a specified radius.
  - `radius`: float - The radius of the circle.
  - `center`: vec3 - The center of the circle.
- `prediction.get_collisions_rectangular(from, to, width)`
  - Determines rectangular collision points within a specified area.
  - `from`: vec3 - The starting point of the rectangle.
  - `to`: vec3 - The ending point of the rectangle.
  - `width`: float - The width of the rectangle.

### Wall Collision Check

`prediction.is_wall_collision(from, to, width)`

- Checks if a path between two points collides with a wall within a specified width.
- `from`: vec3 - The starting point of the path.
- `to`: vec3 - The ending point of the path.
- `width`: float - The width of the path to check.

---

# **Evade**

## Spell Registration

Evade supports the registration of circular, rectangular, and cone-shaped spells for improved gameplay awareness and response.

### Circular Spell Registration

`evade.register_circular_spell(internal_names, menu_name, radius, color, danger_lvl, explosion_delay, is_moving, set_to_player_pos, set_to_player_pos_delay)`

- `internal_names`: Array of Strings - The internal names of the spell particles, like `["monsterAffix_FireOrbs", "anotherParticleName"]`.
- `menu_name`: String - The user-friendly name of the spell that will appear in menus.
- `radius`: Float - The radius of the circular spell area.
- `color`: [color](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - The default color used for visualization.
- `danger_lvl`: `evade::danger_levels` - The danger level of the spell.
- `explosion_delay`: Float - The delay before the spell explodes.
- `is_moving`: Boolean - Indicates whether the spell moves.
- `set_to_player_pos`: Boolean - If true, positions the spell relative to the player's position.
- `set_to_player_pos_delay`: Float - Delay before setting the spell to the player's position.

### Rectangular Spell Registration

`evade.register_rectangular_spell(identifier, names_v, width, length, color, is_dynamic, danger_lvl, is_projectile, projectile_speed, max_time_alive, set_pos_to_player_on_creation, set_to_player_pos_delay)`

- `identifier`: String - A unique identifier for the spell.
- `names_v`: Array of Strings - The internal names of the spell particles.
- `width`: Float - The width of the rectangular spell area.
- `length`: Float - The length of the rectangular spell area.
- `color`: [color](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - The RGBA color used for visualization.
- `is_dynamic`: Boolean - Indicates if the rectangular area changes positions or dimensions dynamically during gameplay.
- `danger_lvl`: `evade::danger_levels` - The danger level of the spell.
- `is_projectile`: Boolean - Indicates whether the spell is a projectile.
- `projectile_speed`: Float - The speed of the projectile.
- `max_time_alive`: Float - Maximum time the spell stays active.
- `set_pos_to_player_on_creation`: Boolean - Positions the spell relative to the player when created.
- `set_to_player_pos_delay`: Float - Delay before setting the spell to the player's position.

### Cone Spell Registration

`evade.register_cone_spell(identifier, names_v, radius, angle, color, danger_lvl, explosion_delay, is_moving)`

- `identifier`: String - A unique identifier for the spell.
- `names_v`: Array of Strings - The internal names of the spell particles.
- `radius`: Float - The radius of the cone's circular base.
- `angle`: Float - The angle of the cone in degrees.
- `color`: [color](https://github.com/qqtnn/diablo_lua_documentation/wiki/Color) - The RGBA color used for visualization.
- `danger_lvl`: `evade::danger_levels` - The danger level of the spell.
- `explosion_delay`: Float - The delay before the spell explodes.
- `is_moving`: Boolean - Indicates whether the spell moves.

> [!TIP]
> Code Example

```lua
local initialized_evade_db = false

-- Main update function to register spells
on_update(function ()
    if initialized_evade_db then
        -- Prevent re-initialization to avoid duplicate registrations
        return
    end

    -- Example: Registering a circular spell
    local circular_spell_particles = {"fire_orb_explosion_example", "mage_fire_blast_example"}
    local circular_spell_name = "Fire Blast Example"
    local circular_spell_radius = 5.0
    local circular_spell_color = color.new(255, 0, 0, 255) -- RGBA: Red
    local circular_spell_danger_level = danger_level.high
    local circular_spell_delay = 2.0
    local circular_spell_moving = true
    local circular_spell_set_to_player_pos = false
    local circular_spell_set_to_player_pos_delay = 0.5

    evade.register_circular_spell(circular_spell_particles, circular_spell_name, circular_spell_radius,
                                  circular_spell_color, circular_spell_danger_level, circular_spell_delay,
                                  circular_spell_moving, circular_spell_set_to_player_pos, circular_spell_set_to_player_pos_delay)

    -- Example: Registering a rectangular spell
    local rectangle_spell_identifier = "Charged Strike Example"
    local rectangle_spell_particles = {"warrior_charge_example", "ground_impact_example"}
    local rectangle_spell_width = 2.5
    local rectangle_spell_length = 12.0
    local rectangle_spell_color = color.new(0, 0, 255, 255) -- RGBA: Blue
    local rectangle_spell_dynamic = true
    local rectangle_spell_danger_level = danger_level.medium
    local rectangle_spell_is_projectile = true
    local rectangle_spell_speed = 10.0
    local rectangle_spell_max_time_alive = 3.0
    local rectangle_spell_set_to_player_pos_on_creation = false
    local rectangle_spell_set_to_player_pos_delay = 0.5

    evade.register_rectangular_spell(rectangle_spell_identifier, rectangle_spell_particles, rectangle_spell_width,
                                     rectangle_spell_length, rectangle_spell_color, rectangle_spell_dynamic,
                                     rectangle_spell_danger_level, rectangle_spell_is_projectile, rectangle_spell_speed,
                                     rectangle_spell_max_time_alive, rectangle_spell_set_to_player_pos_on_creation, rectangle_spell_set_to_player_pos_delay)

    -- Example: Registering a cone spell
    local cone_spell_identifier = "Dragon's Breath Example"
    local cone_spell_particles = {"dragon_fire_example", "burning_wind_example"}
    local cone_spell_radius = 7.0
    local cone_spell_angle = 90
    local cone_spell_color = color.new(255, 165, 0, 255) -- RGBA: Orange
    local cone_spell_danger_level = danger_level.high
    local cone_spell_delay = 3.0
    local cone_spell_moving = false

    evade.register_cone_spell(cone_spell_identifier, cone_spell_particles, cone_spell_radius, cone_spell_angle,
                              cone_spell_color, cone_spell_danger_level, cone_spell_delay, cone_spell_moving)

    -- Mark as initialized to prevent re-inserting information
    initialized_evade_db = true
end)
```

## Danger Zone Analysis

### Is Position Dangerous

`evade.is_dangerous_position(pos)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The position to check.

> [!NOTE]
> Analyzes if a given position lies within a dangerous spell zone, which is crucial for character movement decisions.

### Is Path Through Danger Zone

`evade.is_position_passing_dangerous_zone(pos, source_pos)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The target position.
- `source_pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The source position.

> [!NOTE]
> Checks if the path between two points intersects with any dangerous spell zones, aiding in pathfinding and movement strategies.

### Register Dash

`evade.register_dash(initialize_condition, dash_name, spell_id, range, cast_delay, enable_dash_usage_default_value, enable_dash_for_circular_spells_default_value, enable_dash_for_rect_spells)`

- `initialize_condition`: Boolean - Condition to initialize the dash registration.
- `dash_name`: String - Name of the dash ability.
- `spell_id`: Unsigned Integer - ID of the dash spell.
- `range`: Float - Range of the dash ability.
- `cast_delay`: Float - Delay before the dash is cast.
- `enable_dash_usage_default_value`: Boolean - Default value for enabling dash usage.
- `enable_dash_for_circular_spells_default_value`: Boolean - Default value for enabling dash for circular spells.
- `enable_dash_for_rect_spells`: Boolean - Default value for enabling dash for rectangular spells.

> [!NOTE]
> Registers a dash ability with specified parameters, adding it to the evade system for usage in character movement and avoidance.

> [!TIP]
> Code Example

```lua
local initialized_evade_dash_db = false;
on_update(function ()
    if initialized_evade_dash_db then
        -- only insert information 1 time
        return
    end

    local local_player = get_local_player()
    if not local_player then
        return
    end

    local spell_range = 4.5
    local cast_delay = 0.0
    local teleport_spell_id = 288106
    local is_sorcerer = local_player:get_character_class_id() == 0 -- 0 is sorcerer
    evade.register_dash(is_sorcerer, "Sorcerer Teleport", teleport_spell_id , spell_range , cast_delay, true, true, true)

    local spell_range = 6.5
    local cast_delay = 0.10
    local dash_spell_id = 358761
    local is_rogue= local_player:get_character_class_id() == 3 -- 3 is rogue
    evade.register_dash(is_rogue, "Rogue Dash", dash_spell_id, spell_range , cast_delay, true, true, true)

    initialized_evade_dash_db = true
end)
```

---

# **Pathfinder**

## Overview

The Pathfinder module offers robust tools for character movement and navigation, leveraging both custom pathfinding algorithms and the game engine's native capabilities.

## Path Creation with Game Engine

### Create Path Using Game Engine

`pathfinder.create_path_game_engine(pos)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The destination for path creation.

> [!NOTE]
> Generates a path to the specified position using the game engine's pathfinding functionality. While accurate, it's resource-intensive and best used sparingly. It's recommended to store the path for repeated use rather than generating it multiple times.

## Waypoint Navigation

### Get Next Waypoint

`pathfinder.get_next_waypoint(pos, waypoint_list, threshold)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The current position.
- `waypoint_list`: Table of [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - A list of waypoints.
- `threshold`: Number - The distance threshold for selecting the next waypoint.

> [!NOTE]
> Identifies the next waypoint in a list, ideal for navigating paths generated by `create_path_game_engine`. When used in conjunction with `request_move`, it streamlines movement by avoiding unnecessary move orders.

## Movement Functions

### Force Immediate Movement

`pathfinder.force_move(pos)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The target position for immediate movement.

> [!NOTE]
> Instantly moves the player character to the specified position, overriding any current movement or actions. Useful for urgent or precise movement requirements.

### Request Movement (Optimized)

`pathfinder.request_move(pos)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The desired position to move to.

> [!NOTE]
> Submits a movement request to the player character. Unlike `force_move`, it only sends a command if the player isn't already moving, optimizing movement and reducing command redundancy.

```lua
-- register on_key_release callback to call the code each time you release a key
on_key_release(function(key)

    if key ~= 0x48 then
        return;
    end

    -- this code only reads each time you release: [0x48] H KEY

    local local_player = get_local_player();
    if not local_player then
        return;
    end

    -- move to the cursor position
    local cursor_position = get_cursor_position();
    pathfinder.request_move(cursor_position);
end);

```

## Custom Pathfinding Functions

### Calculate Path Points

Calculates a path from a start position to a goal position using a custom pathfinding algorithm.

`pathfinder.calculate_and_get_path_points(start, goal)`

- `start`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The starting position of the path.
- `goal`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The target position of the path.

> [!NOTE]
> Returns a table of `vec3` waypoints representing the calculated path from start to goal.

## Movement with Pathfinder

### Move to Position with Custom Pathfinder

`pathfinder.move_to_cpathfinder(pos, efficient)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The target position for movement.
- `efficient`: Boolean - If true, optimizes the path for shorter distances.

> [!NOTE]
> This function is best used for short to medium distance movements, utilizing the orbwalker's integrated pathfinder. For longer distances, consider using the game engine's pathfinder. The `efficient` parameter allows for quicker, less resource-intensive path calculations.

### Move to Position with Custom Pathfinding

Initiates movement to a specified position using a custom pathfinding algorithm with various configuration options.

`pathfinder.move_to_cpathfinder_custom_full(pos, algo_type, batch_length, circle_rad, circular_precision, max_algo_steps, anti_stuck_rad, anti_stuck_time)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The target position for movement.
- `algo_type`: Integer - Specifies the algorithm type to use.
- `batch_length`: Float - Defines the batch processing length for the pathfinding algorithm.
- `circle_rad`: Float - The radius used for circular path calculations.
- `circular_precision`: Float - The precision of circular path calculations.
- `max_algo_steps`: Integer - The maximum steps the algorithm will execute before stopping.
- `anti_stuck_rad`: Float - Radius to detect if the character is stuck.
- `anti_stuck_time`: Float - Time to consider the character as stuck.

### Move to Position with Custom Pathfinding (Algorithm 1)

Initiates movement using a specific set of default parameters tailored for a certain type of navigation, with overloads allowing flexibility.

`pathfinder.move_to_cpathfinder_custom_a1(pos, batch_length, circle_rad, max_algo_steps, [anti_stuck_rad, anti_stuck_time])`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The target position for movement.
- `batch_length`: Float - The batch processing length for pathfinding.
- `circle_rad`: Float - The radius used for circular paths.
- `max_algo_steps`: Integer - Maximum algorithm steps to execute.
- `anti_stuck_rad`: Float - (Optional) Radius to check for being stuck.
- `anti_stuck_time`: Float - (Optional) Time to determine if stuck.

### Move to Position with Custom Pathfinding (Algorithm 2)

Similar to Algorithm 1 but uses different default parameters and focuses on circular precision in pathfinding.

`pathfinder.move_to_cpathfinder_custom_a2(pos, circular_precision, max_algo_steps, [anti_stuck_rad, anti_stuck_time])`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The target position for movement.
- `circular_precision`: Float - Precision for circular path calculations.
- `max_algo_steps`: Integer - Maximum steps the algorithm executes.
- `anti_stuck_rad`: Float - (Optional) Radius to check if the character is stuck.
- `anti_stuck_time`: Float - (Optional) Time to determine if stuck.

### Clear Stored Path

`pathfinder.clear_stored_path()`

> [!NOTE]
> Clears the currently stored path in the pathfinder. This can be useful to reset or clear navigation paths.
>
> - Returns: `void`

### Force Move Raw

`pathfinder.force_move_raw(pos)`

- `pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The position to move to.

> [!NOTE]
> Forces a movement to the specified position without considering the current pathfinding logic. This can be useful for direct movement commands.
>
> - Returns: `bool` indicating whether the movement command was successfully issued.

### Sprt Waypoints

`pathfinder.sort_waypoints(waypoint_list, point)`

### Set Last Waypoint Index

`pathfinder.set_last_waypoint_index(value)`

```lua
--- Gets the next waypoint from the waypoint list based on current position and threshold.
--- @param pos vec3
--- @param waypoint_list vec3[]
--- @param threshold number
--- @return vec3
function pathfinder.get_next_waypoint(pos, waypoint_list, threshold) end
-- note: changed on july 20, 2024

--- @param point vec3
--- @param waypoint_list vec3[]
--- list of waypoints for example those you get from get_engine_waypoints
--- and then 2nd parameter for example player_position
function pathfinder.sort_waypoints(waypoint_list, point) end

--- @param value integer
-- this is the index used by pathfinder.get_next_waypoint as reference
-- useful to reset to 1, can be used for other things aswell
function pathfinder.set_last_waypoint_index(value) end
```

---

# **Loot Manager**

## Overview

The Loot Manager module provides a comprehensive set of functions for managing lootable items and objects within the game, enhancing player interactions with the game environment.

## Functions

### Get Item Identifier

`loot_manager.get_item_identifier(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The item to identify.

> [!NOTE]
> Retrieves the unique identifier of an item, crucial for differentiating and tracking items in the game world.

### Is Interactable Object

`loot_manager.is_interactuable_object(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The object to check.

> [!NOTE]
> Determines if the specified object is interactable, aiding in automating interactions within the game.

### Is Lootable Item

`loot_manager.is_lootable_item(obj, exclude_potions, exclude_gold)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The item to check.
- `exclude_potions`: boolean - When this is true, potions will return false so you can easily ignore them.
- `exclude_gold`: boolean - When this is true, gold will return false so you can easily ignore it.

> [!NOTE]
> Checks whether an item is lootable, facilitating inventory management and item collection strategies.

### Is Potion Necessary

`loot_manager.is_potion_necesary()`

> Evaluates the player's current inventory to determine the necessity of looting a potion.

### Can Loot Potion

`loot_manager.can_loot_potion()`

> Assesses whether the player can loot a potion based on inventory space and game conditions.

### Is Gold

`loot_manager.is_gold(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The object to evaluate.

> [!NOTE]
> Identifies if the object in question is gold, an essential aspect of resource management.

### Is Potion

`loot_manager.is_potion(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The object to check.

> [!NOTE]
> Checks if the object is a potion, aiding in automating potion collection and usage.

### Is Shrine

`loot_manager.is_shrine(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The shrine object.

> [!NOTE]
> Determines whether an object is a shrine, useful for automated interactions with game shrines.

### Is Obols

`loot_manager.is_obols(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The object to evaluate.

> [!NOTE]
> Identifies if the object is obols, a specific type of in-game currency or item.

### Is Locked Chest

`loot_manager.is_locked_chest(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The chest object.

> [!NOTE]
> Checks if a chest is locked, which is key for deciding whether to attempt opening it.

### Has Whispering Key

`loot_manager.has_whispering_key(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The object to inspect.

> [!NOTE]
> Determines if an object, typically a chest, contains a whispering key.

### Is Ore Exception

`loot_manager.is_ore_exception(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The ore object.

> [!NOTE]
> Identifies if an ore object is an exception, often used in specialized loot collection logic.

### Is Chest Exception

`loot_manager.is_chest_exception(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The chest object.

> [!NOTE]
> Determines if a chest is an exception, aiding in automated decision-making regarding chest interactions.

### Is Event Trigger Exception

`loot_manager.is_event_trigger_exception(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The event trigger object.

> [!NOTE]
> Checks if an object is an exception in triggering events, important for automating event-related actions.

### Get All Items and Chests Sorted by Distance

`loot_manager.get_all_items_and_chest_sorted_by_distance()`

> Retrieves all lootable items and chests in the game environment, sorted by their distance from the player.

### Any Item Around

`loot_manager.any_item_around(point, threshold, exclude_potions, exclude_gold)`

- `point`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The center point to check around.
- `threshold`: Number - The radius to check within.
- `exclude_potions`, `exclude_gold`: Booleans to exclude specific items.

> [!NOTE]
> Scans for any items within a specified radius, with options to exclude potions and gold, aiding in targeted loot collection.

### Loot Item

`loot_manager.loot_item(obj, exclude_potions, exclude_gold)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The item to loot.
- `exclude_potions`, `exclude_gold`: Booleans to exclude these types of items.

> [!NOTE]
> Executes the action of looting a specified item, with options to filter out potions and gold.

### Loot Item with Orbwalker

`loot_manager.loot_item_orbwalker(item)`

- `item`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The item for the orbwalker to loot.

> [!NOTE]
> Requests the orbwalker to loot a specific item, integrating item collection into movement and combat routines.

### Interact with Object

`loot_manager.interact_with_object(obj)`

- `obj`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The object to interact with.

> [!NOTE]
> Triggers an interaction with the specified game object, useful for engaging with various elements in the game world.

### Interact with Vendor and Sell All

`loot_manager.interact_with_vendor_and_sell_all(vendor)`

- `vendor`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The vendor to interact with.

> [!NOTE]
> Automates the process of interacting with a vendor and selling all items in the player's inventory, streamlining inventory management.

### Sell All Items

`loot_manager.sell_all_items()`

- Executes the action of selling all items in the player's inventory. This function requires the vendor window to be open already.

### Salvage All Items

`loot_manager.salvage_all_items()`

- Executes the action of salvaging all items in the player's inventory. This function requires the vendor window to be open already.

### Sell Specific Item

`loot_manager.sell_specific_item(item)`

- `item`: [`item_data`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Item-Data) - The specific item to sell.
- Sells a specified item from the player's inventory. This function requires the vendor window to be open already.

### Salvage Specific Item

`loot_manager.salvage_specific_item(item)`

- `item`: [`item_data`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Item-Data) - The specific item to salvage.
- Salvages a specified item from the player's inventory. This function requires the vendor window to be open already.

> [!NOTE]
> The actions to sell or salvage items interact directly with the game's vendor interface. Ensure that the vendor interface is open before attempting to use these functions to prevent errors or unexpected behavior.

### Interact with Vendor and Repair All

`loot_manager.interact_with_vendor_and_repair_all(vendor)`

- `vendor`: [`gameobject`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Game-Object) - The vendor to interact with.

### Repair All Items

`loot_manager.repair_all_items()`

- Executes the action of repair all items. This function requires the vendor window to be open already.

### Use Item

`loot_manager.use_item(item_data)`

### Move Item To Stash

`loot_manager.move_item_to_stash(item_data)`

### Move Item From Stash

`loot_manager.move_item_from_stash(item_data)`

### Drop Item

`loot_manager.drop_item(item_data)`

### Buy Item

`loot_manager.buy_item(item_data)`

### Get Current Vendor

`loot_manager.get_current_vendor()`

### Is In Vendor Screen

`loot_manager.is_in_vendor_screen()`

### Get Current Vendor

`loot_manager.get_vendor_currency_type()` `note: 0 gold, 3 obols`

### Get Vendor Items

`loot_manager.get_vendor_items()` `table of item data`

---

# **Utility**

## Overview

The Utility module provides a collection of helper functions designed to assist with various common tasks in game scripting, such as state checks, input handling, and logging.

## Functions

### Is Spell Ready

`utility.is_spell_ready(spell_id)`

- `spell_id`: Integer - The ID of the spell to check.

> [!NOTE]
> Checks if a specific spell is ready to be cast. This is crucial for managing cooldowns and ensuring spells are available when needed.

### Is Spell Upgraded

`utility.is_spell_upgraded(spell_id)`

- `spell_id`: Integer - The ID of the spell to check.

> [!NOTE]
> Determines if a spell has been upgraded, which can affect its power, range, or effects.

### Is Spell Available

`utility.is_spell_available(spell_id)`

- `spell_id`: Integer - The ID of the spell to check.

> [!NOTE]
> Verifies if a spell is currently available to the player, considering factors like unlock status or current game state.

### Get Spell Charges

`utility.get_spell_charges(spell_id)`

- `spell_id`: Integer - The ID of the spell.

> [!NOTE]
> Retrieves the current number of charges for a spell, useful for spells that can be cast multiple times before a full cooldown.

### Get Spell Max Charges

`utility.get_spell_max_charges(spell_id)`

- `spell_id`: Integer - The ID of the spell.

> [!NOTE]
> Returns the maximum number of charges a spell can hold.

### Get Amount of Potion Charges

`utility.get_amount_of_potion_charges()`

> [!NOTE]
> Gets the current number of potion charges available to the player.

### Get Max Amount of Potion Charges

`utility.get_max_amount_of_potion_charges()`

> [!NOTE]
> Retrieves the maximum capacity for potion charges.

### Is Key Pressed

`utility.is_key_pressed(key_code)`

- `key_code`: Integer - The code of the key to check.

> [!NOTE]
> Checks if a specific key is currently being pressed. This is essential for custom input handling and hotkey implementation.

### Get Latency

`utility.get_latency()`

> [!NOTE]
> Returns the current network latency, allowing scripts to adjust behavior based on connection quality.

### Get Time Since Start

`utility.get_time_since_start()`

> [!NOTE]
> Provides the time elapsed since the game or script started, useful for timers and duration tracking.

### Get Time Since Injection

`utility.get_time_since_injection()`

> [!NOTE]
> Returns the time elapsed since the script was injected into the game process.

### Get Time ms

`utility.get_time_ms()`

> [!NOTE]
> Gets the current system time in milliseconds, offering high-precision timing for performance measurements or synchronization.

### Get Frame Count

`utility.get_frame_count()`

> [!NOTE]
> Retrieves the total number of frames rendered since the start, useful for frame-rate independent calculations.

### Get Framerate

`utility.get_framerate()`

> [!NOTE]
> Returns the current framerate (FPS) of the game.

### Get Screen Size

`utility.get_screen_size()`

> [!NOTE]
> Gets the dimensions of the game window or screen, important for UI positioning and scaling.

### Get Mouse Position

`utility.get_mouse_pos()`

> [!NOTE]
> Retrieves the current screen coordinates of the mouse cursor.

### Get Cursor Position

`utility.get_cursor_pos()`

> [!NOTE]
> Returns the in-game world coordinates corresponding to the cursor's position.

### Is Window Focused

`utility.is_window_focused()`

> [!NOTE]
> Checks if the game window is currently focused, allowing scripts to pause or reduce activity when the user is alt-tabbed.

### Log to Console

`utility.log_to_console(message)`

- `message`: String - The message to log.

> [!NOTE]
> Outputs a message to the game's or script's console, vital for debugging and status updates.

### Log to File

`utility.log_to_file(message)`

- `message`: String - The message to log.

> [!NOTE]
> Writes a message to a log file, useful for persistent logging and post-session analysis.

---

# **World**

## Overview

The World module provides functions to interact with the game world, including retrieving game objects, players, and managing world states.

## Functions

### Get Game Object

`world.get_game_object(id)`

- `id`: Integer - The unique identifier of the game object.

> [!NOTE]
> Retrieves a game object by its unique ID. This is essential for accessing specific entities within the game world.

### Get Player

`world.get_player(name)`

- `name`: String - The name of the player.

> [!NOTE]
> Finds and returns a player object based on their name. Useful for interactions involving specific players.

### Get Local Player

`world.get_local_player()`

> [!NOTE]
> Returns the object representing the local player (the user's character). This is frequently used for accessing player-specific data and actions.

### Get Game Objects

`world.get_game_objects()`

> [!NOTE]
> Retrieves a list of all game objects currently in the world. This function is useful for iterating over entities to find targets, items, or other points of interest.

### Get Nearby Players

`world.get_nearby_players(radius)`

- `radius`: Float - The radius within which to search for players.

> [!NOTE]
> Returns a list of players within a specified radius of the local player. Useful for area-of-effect logic or social interactions.

### Get World State

`world.get_world_state()`

> [!NOTE]
> Retrieves the current state of the game world, which may include information like the current zone, difficulty level, or active events.

### Get Current Zone Name

`world.get_current_zone_name()`

> [!NOTE]
> Returns the name of the zone where the player is currently located.

### Get Current World Name

`world.get_current_world_name()`

> [!NOTE]
> Returns the name of the world or realm the player is currently in.

### Is Point Walkable

`world.is_point_walkable(point)`

- `point`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The position to check.

> [!NOTE]
> Checks if a specific point in the world is walkable. Crucial for pathfinding and movement logic.

### Is Wall

`world.is_wall(point)`

- `point`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The position to check.

> [!NOTE]
> Determines if a specific point corresponds to a wall or obstacle.

### Get Floor Height

`world.get_floor_height(point)`

- `point`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The position to check.

> [!NOTE]
> Retrieves the height of the floor at a given position, useful for 3D calculations and positioning.

### World to Screen

`world.world_to_screen(world_pos)`

- `world_pos`: [`vec3`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-3) - The world position to convert.

> [!NOTE]
> Converts a 3D world position to 2D screen coordinates. Essential for rendering UI elements over game objects.

### Screen to World

`world.screen_to_world(screen_pos)`

- `screen_pos`: [`vec2`](https://github.com/qqtnn/diablo_lua_documentation/wiki/Vector-2) - The screen position to convert.

> [!NOTE]
> Converts 2D screen coordinates to a 3D world position. Useful for handling mouse clicks and interactions in the game world.

---

# **Auto Play**

## Overview

The Auto Play module provides functionality to automate gameplay actions, such as enabling or disabling auto-play features and configuring settings.

## Functions

### Set Active

`auto_play.set_active(is_active)`

- `is_active`: Boolean - Set to `true` to enable auto-play, `false` to disable.

> [!NOTE]
> Toggles the auto-play feature on or off. When active, the script will take control of gameplay actions based on its logic.

### Is Active

`auto_play.is_active()`

> [!NOTE]
> Checks if the auto-play feature is currently active.

### Set Mode

`auto_play.set_mode(mode)`

- `mode`: String - The mode to set for auto-play (e.g., "farm", "level", "pvp").

> [!NOTE]
> Sets the operational mode for auto-play, allowing it to adapt its behavior to different gameplay goals.

### Get Mode

`auto_play.get_mode()`

> [!NOTE]
> Retrieves the current mode of the auto-play feature.

### Set Config

`auto_play.set_config(config_name, value)`

- `config_name`: String - The name of the configuration setting.
- `value`: Variant - The value to set for the configuration.

> [!NOTE]
> Updates a specific configuration setting for auto-play, allowing for fine-tuning of its behavior.

### Get Config

`auto_play.get_config(config_name)`

- `config_name`: String - The name of the configuration setting to retrieve.

> [!NOTE]
> Gets the current value of a specific auto-play configuration setting.
