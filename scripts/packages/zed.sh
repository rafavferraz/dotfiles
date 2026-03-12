#!/bin/bash

if command -v zed &>/dev/null; then
    echo "zed already installed"
    exit 0
fi

echo "=== Installing zed ==="
curl -sS https://zed.dev/install.sh | sh
