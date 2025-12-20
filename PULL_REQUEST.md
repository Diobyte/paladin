Title: Add tests for targeting/collision, small refactors, and test runner

Summary:

- Added tests covering target selector circular area (`get_most_hits_circular`), actor collision (`CheckActorCollision`), prediction wall-collision filtering, and range edge-cases.
- Replaced remaining direct cast patterns with `my_utility.try_cast_spell` for consistency and single point of behavior.
- Added a lightweight test runner (`Test/run.lua`) and assertion helpers for clearer test results locally and in CI.
- Fixed compatibility issues (removed `goto`/`::continue::` labels) to support Lua 5.1 environments.

Test Results:

- All tests pass locally using the new runner: `lua Test/run.lua` → Total: 7 Passed: 7 Failed: 0

Why this change:

- Improves test coverage for targeting and collision logic (important for AoE/spell placement correctness).
- Reduces duplicated casting logic and centralizes casting behavior in `my_utility.try_cast_spell`.
- Makes CI test runs easier to run and read via a single runner.

Notes for reviewers:

- The `CheckActorCollision` implementation was simplified to be robust in unit test environments and should be functionally equivalent to prior math.
- CI updated to run `lua Test/run.lua` if `lua` is installed on the runner.

Request: Please review the changes focusing on the logic in `my_target_selector` (collision & area checks), the spell refactors for correctness, and the new tests. Thanks!
