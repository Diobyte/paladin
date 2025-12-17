# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2025-12-17

### ✨ Added

- **Auradin Holy Light Aura Build**: Complete specialized build optimized for maximum DPS using Holy Light Aura as the primary damage source with Blessed Hammer spam, Falling Star oath setup, and constant aura maintenance
- **Dynamic Spell Priority System**: Real-time adjustments based on Faith and health levels with automatic priority boosts for resource generation and defensive spells
- **Emergency Logic**: Auradin-specific critical situation handling for low Faith (<20%) and health (<25%) scenarios

### 🐛 Fixed

- **API Compliance**: Corrected all function calls to match official Diablo 4 Lua API documentation (`get_ressource` → `get_primary_resource_current`, `get_health` → `get_current_health`)
- **Build Selector**: Fixed Auradin build index conflict that prevented it from appearing in the dropdown menu

### 🔄 Changed

- **Build Selector**: Added "Auradin Holy Light Aura" as the 14th build option
- **Spell Priority Logic**: Enhanced with real-time monitoring and dynamic adjustments for improved gameplay

### 📊 Technical Details

- **Dynamic Thresholds**: Faith (25%, 40%, 60%, 80%) and Health (30%, 50%, 70%) monitoring
- **Performance**: Minimal impact real-time resource monitoring with optimized calculations

---

## [1.2.0] - Previous Version

- Initial release with 12 specialized Paladin builds
- Basic spell priority system
- Core targeting and utility functions</content>
  <parameter name="filePath">c:\Users\Diobit27\Documents\GitHub\paladin\CHANGELOG.md
