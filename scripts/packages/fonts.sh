#!/bin/bash

echo "=== Installing fonts ==="
FONT_DIR=~/.local/share/fonts
mkdir -p "$FONT_DIR"
curl -fLo "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" \
    https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf
fc-cache -f
