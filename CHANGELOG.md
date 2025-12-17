# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2025-12-17

### Added

- **Auradin Holy Light Aura Build**: New specialized build optimized for maximum DPS using Holy Light Aura as the primary damage source

  - Holy Light Aura prioritized as highest damage spell (after mobility)
  - Falling Star for oath setup and power generation
  - Blessed Hammer as primary spam skill for Faith generation and aura procs
  - Optimized spell priority for constant aura uptime and Resplendence glyph refresh
  - Rally for Faith restoration and defensive buffs
  - Aegis as primary defensive ultimate

- **Dynamic Spell Priority System**: Real-time spell priority adjustments based on current game state

  - **Faith Management**: Automatically boosts Faith-generating spells (Blessed Hammer, Zeal, Rally) when Faith drops below thresholds (25%, 40%, 60%, 80%)
  - **Health Monitoring**: Prioritizes defensive spells (Aegis, Purify, Rally) when health drops below critical levels (30%, 50%, 70%)
  - **Emergency Adjustments**: Auradin-specific emergency logic for critical Faith (<20%) and health (<25%) situations

- **Auradin Emergency Logic**:
  - Critical Faith (<20%): Rally prioritized immediately after evade spells
  - Critical Health (<25%): Aegis prioritized immediately after evade spells
  - Enhanced survivability and resource management for high-risk gameplay

### Fixed

- **API Compliance**: Corrected all function calls to match official Diablo 4 Lua API documentation
  - `get_ressource(0)` → `get_primary_resource_current()`
  - `get_ressource_max(0)` → `get_primary_resource_max()`
  - `get_health()` → `get_current_health()`
  - `get_max_health()` remains correct
- **Build Selector Index Conflict**: Fixed Auradin build index from 12 to 13 to prevent overwriting Zenith Aegis Tank build
- **Dynamic Adjustments Bug**: Corrected Auradin build index reference in dynamic adjustment function

### Changed

- **Build Selector**: Added "Auradin Holy Light Aura" as 14th build option (index 13)
- **Spell Priority Logic**: Enhanced with real-time monitoring and dynamic adjustments for all builds
- **Resource Monitoring**: Improved Faith and health tracking with threshold-based priority boosts

### Technical Details

- **Dynamic Adjustment Thresholds**:
  - Faith: Emergency (25%), High (40%), Medium (60%), Low (80%)
  - Health: Critical (30%), Low (50%), Moderate (70%)
- **Auradin Build Features**:
  - Holy Light Aura as core damage mechanic
  - Blessed Hammer spam for resource generation
  - Consecration for powerful buffs
  - Condemn for enemy positioning
  - Constant aura maintenance for optimal DPS

### Performance

- Real-time resource monitoring with minimal performance impact
- Dynamic priority calculations performed only when needed
- Optimized spell priority lookups for faster decision making

---

## [1.2.0] - Previous Version

- Initial release with 12 specialized Paladin builds
- Basic spell priority system
- Core targeting and utility functions</content>
  <parameter name="filePath">c:\Users\Diobit27\Documents\GitHub\paladin\CHANGELOG.md
