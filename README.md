# Paladin Rotation Plugin

This plugin automates Paladin rotation logic.

## Development

- Enable debug messages in-game via the plugin menu: Settings -> Enable Debug. Console output is only printed when debug is enabled.
- To maintain aura/buff spells continuously ("Cast on Cooldown"), use the menu option in each aura; the plugin now centralizes this pattern with `my_utility.try_maintain_buff` to avoid duplication.
- A helper `my_utility.try_cast_spell` is available to centralize casting/recording logic for simple cast blocks.

## CI

A basic GitHub Action (`.github/workflows/ci.yml`) checks Lua syntax using `luac -p` for every `.lua` file on push/pull requests.

## Contributing

Open a PR with a short description of changes and add tests if applicable.
