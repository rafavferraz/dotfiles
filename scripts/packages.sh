#!/bin/bash

echo "=== Installing packages ==="
sudo apt update
sudo apt install -y make git gh curl kitty fish bat btop htop tree || true

DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$DIR/packages/lazygit.sh"
bash "$DIR/packages/starship.sh"
bash "$DIR/packages/yazi.sh"
bash "$DIR/packages/fonts.sh"
bash "$DIR/packages/zed.sh"
bash "$DIR/packages/docker.sh"
bash "$DIR/packages/nvidia.sh"
bash "$DIR/packages/clang.sh"
bash "$DIR/packages/claude.sh"
