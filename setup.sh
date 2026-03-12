#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$DIR/scripts/cleanup_home.sh"
bash "$DIR/scripts/folders.sh"
bash "$DIR/scripts/packages.sh"
bash "$DIR/scripts/auth.sh"
bash "$DIR/scripts/shell.sh"
bash "$DIR/scripts/dotfiles.sh"

echo "=== Done! ==="
echo "Restart Kitty to apply changes."
echo "Run 'kitty +kitten themes' to pick a theme."
