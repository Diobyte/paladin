## Unreleased

### Added

- Tests for target selection and collision behavior (`Test/test_target_selector_circular.lua`, `Test/test_collision.lua`, `Test/test_range_and_melee.lua`) ✅
- Simple test runner and small assertion helpers (`Test/run.lua`, `Test/assert.lua`) ✅
- Added `busted` test integration and converted some tests to use `busted` for improved test reporting ✅

### Changed

- Replaced remaining direct cast+cooldown blocks with `my_utility.try_cast_spell` for consistency in several spells (e.g., `blessed_hammer`, `shield_bash`, `blessed_shield`, `spear_of_the_heavens`, `clash`, `advance`) ✅
- Improved `CheckActorCollision` implementation to be robust in test environment and runtime ✅
- CI now runs the test runner (`lua Test/run.lua`) when `lua` is available ✅

### Fixed

- Make `my_target_selector` compatible with Lua 5.1 by removing `goto`/label `continue` usage and using portable control flow ✅
