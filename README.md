# ⚔️ Paladin Dirty - Diablo 4 Rotation Script

<div align="center">

![Diablo 4 Paladin](https://img.shields.io/badge/Diablo%204-Paladin-red?style=for-the-badge)
![Version](https://img.shields.io/badge/Version-1.0.1-blue?style=for-the-badge)
![Season](https://img.shields.io/badge/Season-11-orange?style=for-the-badge)
![Lua](https://img.shields.io/badge/Lua-Scripting-yellow?style=for-the-badge)

**🔥 Ultimate Paladin Automation for Diablo 4 Season 11 🔥**

_A 1:1 port of the legendary [RotationSpiritborn_Dirty](https://github.com/Dirty-git/RotationSpiritborn_Dirty) repository, masterfully adapted for the **Paladin** class._

[📥 Download](#-installation) • [🎮 Usage](#-usage) • [⚙️ Configuration](#-customization) • [🐛 Troubleshooting](#-troubleshooting)

---

## 📋 Table of Contents

- [🌟 Overview](#-overview)
- [🚀 Features](#-features)
- [📦 Installation](#-installation)
- [🎮 Usage](#-usage)
- [📁 Project Structure](#-project-structure)
- [🔧 Customization](#-customization)
- [🐛 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📊 Performance & Compatibility](#-performance--compatibility)
- [🙏 Credits & Acknowledgments](#-credits--acknowledgments)
- [📜 License & Legal](#-license--legal)

---

</div>

## 🌟 Overview

Welcome to **Paladin Dirty** - the most advanced automated rotation system for Paladin in Diablo 4! This script brings the proven Spiritborn rotation logic to the holy warrior class, featuring intelligent targeting, spell prioritization, and comprehensive customization options.

### ✨ Key Highlights

- 🎯 **Precision Targeting**: Advanced enemy evaluation with scoring based on type, buffs, and positioning
- ⚡ **Lightning-Fast Rotation**: Optimized spell casting with configurable priority system
- 🎨 **Visual Debug Tools**: On-screen overlays for targets, ranges, and combat analysis
- 🎛️ **Intuitive Menu System**: In-game configuration for all settings and preferences
- 🔄 **Orbwalker Integration**: Seamless compatibility with movement and combat systems
- 📊 **Performance Optimized**: Minimal impact on game performance with efficient algorithms

---

## 🚀 Features

### 🎯 Combat System

- **1:1 Port Accuracy**: Faithfully mirrors the original Spiritborn structure with Paladin adaptations
- **Smart Targeting**: Evaluates enemies by threat level, distance, and special properties
- **Spell Prioritization**: Customizable casting order via dedicated priority file
- **Multi-Mode Support**: PvP, Clear, and Flee modes with orbwalker integration

### 🎨 Visualization

- **Debug Overlays**: Optional on-screen displays for targets and ranges
- **Range Indicators**: Visual circles for melee and targeting ranges
- **Enemy Highlighting**: Color-coded enemy markers for different types
- **Cursor Targeting**: Special indicators for best cursor targets

### ⚙️ Customization

- **Menu-Driven Config**: Easy in-game settings adjustment
- **Spell Toggles**: Individual enable/disable for all abilities
- **Range Settings**: Adjustable targeting and evaluation distances
- **Performance Tuning**: Refresh rates and debug level controls

---

## 📦 Installation

### Quick Setup (3 Steps)

1. **Clone the Repository**

   ```bash
   git clone https://github.com/Diobyte/paladin.git
   cd paladin
   ```

2. **Deploy to Loader**

   ```
   Copy the 'paladin' folder to:
   your_loader\scripts\paladin\
   ```

3. **Load in Game**
   - Launch Diablo 4
   - Press `F5` to reload Lua scripts
   - Press `F1` to open console and verify: _"Lua Plugin - Paladin Dirty - Version 1.0.1"_

### 📋 Requirements

| Component        | Requirement          | Notes                                   |
| ---------------- | -------------------- | --------------------------------------- |
| **Game Version** | Diablo 4 Season 11+  | Compatible with latest patches          |
| **Class**        | Paladin (IDs: 7/8/9) | Auto-detects class variants             |
| **Lua Loader**   | Compatible D4 Loader | Must support orbwalker/graphics modules |
| **Spells**       | Paladin Abilities    | Script detects equipped spells          |

---

## 🎮 Usage

### Getting Started

1. **Enable Plugin**: Navigate to _"Paladin [Dirty] v1.0.1"_ in the in-game menu
2. **Check "Enable Plugin"**: Activate the rotation system
3. **Equip Spells**: Ensure your Paladin has the desired abilities equipped
4. **Start Combat**: The script will automatically handle rotations!

### ⚙️ Configuration Options

#### Main Settings

- **Enable Plugin**: Master toggle for the entire system
- **Enemy Count Threshold**: Minimum enemies to trigger area spells
- **Max Targeting Range**: How far to look for targets
- **Cursor Targeting Radius**: Area around cursor for special targeting

#### Debug Features

- **Draw Targets**: Show target indicators on screen
- **Draw Max Range**: Display maximum targeting circle
- **Draw Melee Range**: Show close-combat range indicator
- **Draw Enemy Circles**: Highlight all detected enemies

### 🗡️ Spell Categories

| Category         | Spells                                                | Description            |
| ---------------- | ----------------------------------------------------- | ---------------------- |
| **🛡️ Auras**     | `defiance_aura`, `fanaticism_aura`, `holy_light_aura` | Self-buff abilities    |
| **⚔️ Core DPS**  | `blessed_hammer`, `zeal`, `divine_lance`              | Primary damage dealers |
| **💥 Ultimates** | `zenith`, `heavens_fury`, `spear_of_the_heavens`      | High-impact finishers  |
| **🎯 Special**   | `advance`, `rally`, `shield_charge`                   | Utility and mobility   |

---

## 📁 Project Structure

```
paladin/
├── 📄 main.lua                    # 🎯 Core logic & menu system
├── 📄 spell_priority.lua          # ⚡ Spell casting order
├── 📁 my_utility/                 # 🛠️ Utility modules
│   ├── 📄 my_utility.lua          # 🔧 Core utilities
│   ├── 📄 my_target_selector.lua  # 🎯 Targeting logic
│   └── 📄 spell_data.lua          # 📚 Spell definitions
└── 📁 spells/                     # ✨ Individual spell files
    ├── 🛡️ auras/                  # Self-cast abilities
    ├── ⚔️ damage/                 # Combat spells
    └── 🎯 special/                # Utility spells
```

---

## 🔧 Customization

### Spell Priority Tuning

Edit `spell_priority.lua` to customize casting order:

```lua
local spell_priority = {
    -- 🛡️ defensives and auras
    "holy_light_aura",
    "defiance_aura",
    "fanaticism_aura",

    -- ⚔️ main damage abilities
    "blessed_hammer",
    "zeal",
    "divine_lance",

    -- 💥 ultimates
    "zenith",
    "heavens_fury"
}
```

### Advanced Settings

- **Enemy Evaluation**: Adjust scoring weights for different enemy types
- **Refresh Intervals**: Balance performance vs responsiveness
- **Debug Levels**: Control visualization verbosity

---

## 🐛 Troubleshooting

### Common Issues & Solutions

| Problem                     | Solution                                                                       |
| --------------------------- | ------------------------------------------------------------------------------ |
| **Script won't load**       | Check console (F1) for errors, ensure folder is in `scripts/`, reload with F5  |
| **Spells not casting**      | Verify spells are equipped, check menu toggles, ensure proper target selection |
| **Performance lag**         | Reduce targeting refresh rate, disable debug visualizations                    |
| **"use_ability nil" error** | Reload scripts after updates, check for syntax errors                          |
| **Wrong class detection**   | Ensure you're playing Paladin (IDs 7/8/9)                                      |

### Debug Mode

Enable debug options to visualize:

- 🔴 **Targets**: Red circles around detected enemies
- 🔵 **Ranges**: Blue circles for targeting distances
- 🟡 **Cursor**: Yellow indicators for cursor-based targeting
- 🟢 **Melee**: Green circles for close-range combat

---

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly in-game
5. Submit a pull request

### Development Guidelines

- Maintain 1:1 structure parity with original
- Test all changes with Paladin class
- Update documentation for new features
- Follow existing code style and patterns

---

## 📊 Performance & Compatibility

### System Requirements

- **RAM**: Minimal additional usage
- **CPU**: Negligible impact with optimizations
- **Network**: No additional bandwidth required

### Compatibility Matrix

| Feature           | Status           | Notes                       |
| ----------------- | ---------------- | --------------------------- |
| **Orbwalker**     | ✅ Full Support  | Movement & combat modes     |
| **Evade**         | ✅ Compatible    | Works with evade system     |
| **Loot Manager**  | ✅ Compatible    | No conflicts detected       |
| **Other Classes** | ❌ Not Supported | Paladin-only implementation |

---

## 🙏 Credits & Acknowledgments

### Core Team

- **🎯 Original Creator**: [Dirty-git](https://github.com/Dirty-git) - _RotationSpiritborn_Dirty_
- **⚔️ Paladin Adaptation**: [Diobyte](https://github.com/Diobyte) - _Port & Optimization_

### Special Thanks

- **Diablo 4 Community**: For inspiration and feedback
- **Lua Scripting Community**: For tools and documentation
- **Beta Testers**: For rigorous testing and bug reports

### Resources

- [Diablo 4 Lua API Documentation](https://github.com/qqtnn/diablo_lua_documentation)
- [Wowhead Diablo 4 Database](https://www.wowhead.com/diablo-4)
- [Original Spiritborn Repository](https://github.com/Dirty-git/RotationSpiritborn_Dirty)

---

## 📜 License & Legal

### License

This project is a derivative work based on the original RotationSpiritborn_Dirty repository. Please refer to the [original license](https://github.com/Dirty-git/RotationSpiritborn_Dirty/blob/main/LICENSE) for usage terms and conditions.

### Disclaimer

```
⚠️ EDUCATIONAL & PERSONAL USE ONLY

This script is provided for educational purposes and personal use within Diablo 4.
Users are responsible for compliance with Blizzard's Terms of Service and game policies.

USE AT YOUR OWN RISK - The developers are not responsible for any consequences
resulting from the use of this software, including account bans or game restrictions.
```

---

<div align="center">

**Made with ❤️ for the Diablo 4 Paladin Community**

---

[⬆️ Back to Top](#-paladin-dirty---diablo-4-rotation-script) • [🐛 Report Issues](https://github.com/Diobyte/paladin/issues) • [💬 Discussions](https://github.com/Diobyte/paladin/discussions)

</div>
