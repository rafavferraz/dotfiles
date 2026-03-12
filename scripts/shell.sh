#!/bin/bash

echo "=== Configuring fish shell ==="
FISH_PATH="$(which fish)"
if [ -n "$FISH_PATH" ] && ! grep -q "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi
if [ -n "$FISH_PATH" ] && [ "$SHELL" != "$FISH_PATH" ]; then
    chsh -s "$FISH_PATH"
fi
