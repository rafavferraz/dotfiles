#!/bin/bash

if command -v starship &>/dev/null; then
    echo "starship already installed"
    exit 0
fi

echo "=== Installing starship ==="
curl -sS https://starship.rs/install.sh | sh -s -- -y
