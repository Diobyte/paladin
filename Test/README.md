# Tests

Currently we run a basic Lua syntax check via GitHub Actions using `luac -p` for each `.lua` file.

To run locally (Ubuntu/Debian):

```bash
sudo apt update
sudo apt install -y lua5.3
for f in $(git ls-files '*.lua'); do luac -p "$f" || (echo "Syntax error in $f" && exit 1); done
```
