#!/bin/bash

if command -v clang++ &>/dev/null; then
    echo "clang++ already installed"
    exit 0
fi

echo "=== Installing clang++ ==="
sudo apt install -y clang
