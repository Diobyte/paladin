# DirtyDio Paladin Plugin

A comprehensive Paladin combat routine for Diablo 4, featuring multiple build logic configurations, automated targeting, and customizable spell priorities.

## Features
- **Multiple Build Support**: Includes logic for Hammerdin, Arbiter, Auradin, and more.
- **Smart Targeting**: Automatically evaluates targets based on range, health, and priority (Elites/Bosses).
- **Orbwalker Integration**: Works seamlessly with the orbwalker for movement and kiting.
- **Customizable**: Fine-tune settings for every spell.

## Configuration Guide

### 1. Initial Setup
1. **Open the Menu**: While the game is focused, press the menu key (default `Alt+F1`) to open the plugin interface.
2. **Select Your Build**: **CRITICAL STEP**. Go to `Settings > Build Selector` and choose the build that matches your in-game loadout (e.g., "Auradin", "Hammerkuna"). This ensures the plugin uses the correct spell priority and rotation logic for maximum DPS.

### 2. Spell Configuration
You can customize the behavior of each spell individually:
- **Equipped Spells**: Shows spells currently detected on your action bar.
- **Inactive Spells**: Shows all other supported spells not currently equipped.
- **Adjust Settings**: Click on any spell name to expand its specific options (Enable/Disable, Targeting Mode, Health Thresholds).

## Settings & Usage Scenarios

Understanding when to use specific settings can greatly improve performance:

- **Targeting Refresh Interval**:
  - *Scenario*: High-density mob packs.
  - *Usage*: Lower this value (e.g., 0.1s) for faster target switching. Increase it if you experience FPS drops.

- **Enemy Evaluation Radius**:
  - *Scenario*: Using large AoE spells like *Consecration* or *Falling Star*.
  - *Usage*: Increase this value to ensure the plugin considers enemies further away when calculating the best target cluster for AoE efficiency.

- **Force Target Boss/Elite**:
  - *Scenario*: Boss fights or high-tier Pit runs.
  - *Usage*: Enable this to ensure your single-target damage is always focused on the highest priority threat, ignoring trash mobs that might distract the targeting logic.

- **Cursor Targeting Radius**:
  - *Scenario*: Builds requiring precise positioning.
  - *Usage*: Adjust this to define how close an enemy must be to your mouse cursor to be considered a valid target when using "Cursor" targeting modes.

- **Custom Enemy Weights**:
  - *Scenario*: Advanced tuning.
  - *Usage*: Tweak these values to make the targeting logic strictly prefer specific enemy types (e.g., giving Champions a massive weight to nuke them first).

## Disclaimer
This software is an unofficial plugin created for educational and research purposes only.

- **Not Affiliated**: This project is not affiliated with, endorsed by, or connected to Blizzard Entertainment, Diablo, or any of their subsidiaries or affiliates.
- **No Warranty**: The software is provided "as is", without warranty of any kind, express or implied.
- **Use at Your Own Risk**: The authors and contributors accept no responsibility for any bans, account suspensions, or damages resulting from the use of this software. Users are solely responsible for compliance with the Terms of Service of any third-party software or games they interact with.
