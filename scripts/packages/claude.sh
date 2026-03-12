#!/bin/bash

echo "=== Adding ~/.local/bin to PATH ==="
if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi
export PATH="$HOME/.local/bin:$PATH"

if command -v claude &>/dev/null; then
    echo "claude already installed"
    exit 0
fi

echo "=== Installing Claude Code ==="
curl -fsSL https://claude.ai/install.sh | bash
