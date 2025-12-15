# Paladin Dirty - Diablo 4 Rotation Script

A 1:1 port of the [RotationSpiritborn_Dirty](https://github.com/Dirty-git/RotationSpiritborn_Dirty) repository, adapted for the **Paladin** class in **Diablo 4 Season 11**.

## Overview

This Lua script provides an automated rotation system for the Paladin class, featuring advanced targeting, spell prioritization, and customizable settings. It includes support for all Paladin spells, with logic for auras, targeted abilities, and area-of-effect spells.

## Features

- **1:1 Port Accuracy**: Strictly mirrors the original Spiritborn structure with Paladin-specific adaptations.
- **Advanced Targeting**: Includes enemy evaluation with scoring based on type, buffs, and proximity.
- **Spell Prioritization**: Configurable casting order via `spell_priority.lua`.
- **Debug Visualization**: Optional on-screen overlays for targets, ranges, and enemy circles.
- **Menu System**: In-game menu for enabling/disabling spells, adjusting settings, and debug options.
- **Orbwalker Integration**: Works seamlessly with the game's orbwalker for movement and combat.

## Installation

1. **Clone or Download** the repository:

   ```
   git clone https://github.com/Diobyte/paladin.git
   ```

2. **Place in Loader Folder**:

   - Copy the `paladin` folder to your Diablo 4 Lua loader's `scripts` directory (e.g., `loader_folder_name\scripts\paladin`).

3. **Load in-Game**:
   - Launch Diablo 4.
   - Reload Lua scripts with the default keybind (`F5`).
   - Open the console with `F1` to confirm loading: "Lua Plugin - Paladin Dirty - Version 1.5.6".

## Usage

- **Enable the Plugin**: In the in-game menu, navigate to "Paladin [Dirty] v1.5.6" and check "Enable Plugin".
- **Configure Spells**: Equip the desired Paladin spells in-game. The script will automatically detect and prioritize them.
- **Settings**:
  - Adjust targeting ranges, enemy weights, and debug options in the "Settings" menu.
  - Enable debug to visualize targets and ranges.
- **Orbwalker Modes**: The script supports PvP, Clear, and Flee modes via the orbwalker.

### Spell List

- **Auras** (Self-cast): `defiance_aura`, `fanaticism_aura`, `holy_light_aura`
- **Targeted/AoE**: `advance`, `arbiter_of_justice`, `blessed_hammer`, `blessed_shield`, `brandish`, `clash`, `condemn`, `consecration`, `divine_lance`, `falling_star`, `heavens_fury`, `holy_bolt`, `rally`, `shield_charge`, `spear_of_the_heavens`, `zeal`, `zenith`

## Requirements

- **Diablo 4**: Season 11 or compatible version.
- **Paladin Class**: Script is tailored for Paladin (IDs 7/8/9).
- **Lua Loader**: A compatible Lua script loader for Diablo 4 (e.g., with orbwalker, evade, and graphics modules).
- **Equipped Spells**: Ensure Paladin spells are equipped for the script to function.

## File Structure

```
paladin/
├── main.lua                 # Main script with targeting, menu, and logic
├── spell_priority.lua       # Defines spell casting order
├── my_utility/              # Utility modules
│   ├── my_utility.lua       # Core utilities and plugin label
│   ├── my_target_selector.lua # Target selection logic
│   └── spell_data.lua       # Spell IDs and enemy data
└── spells/                  # Individual spell files (logics and menus)
    ├── advance.lua
    ├── arbiter_of_justice.lua
    └── ... (20 more Paladin spells)
```

## Customization

- **Spell Priority**: Edit `spell_priority.lua` to change casting order.
- **Enemy Weights**: Adjust scoring for different enemy types in the menu.
- **Debug Options**: Enable visualizations for testing and tuning.

## Troubleshooting

- **Script Not Loading**: Check console for errors. Ensure the folder is in `scripts/` and reload with F5.
- **Spells Not Casting**: Verify spells are equipped and enabled in the menu.
- **Performance Issues**: Reduce targeting refresh interval or disable debug.
- **Errors**: If "use_ability nil" or similar occurs, ensure the script is reloaded after updates.

## Credits

- **Original Repository**: [RotationSpiritborn_Dirty](https://github.com/Dirty-git/RotationSpiritborn_Dirty) by Dirty-git.
- **Adaptation**: Ported for Paladin by Diobyte.
- **Diablo 4 Lua API**: Utilizes game-specific functions for scripting.

## License

This project is a derivative work. Refer to the original repository's license for usage terms.

## Disclaimer

This script is for educational and personal use in Diablo 4. Ensure compliance with game terms of service. Use at your own risk.
