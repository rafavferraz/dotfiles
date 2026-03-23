#!/bin/bash

if command -v clang++ &>/dev/null; then
    echo "clang++ already installed"
else
    echo "=== Installing clang++ ==="
    sudo apt install -y clang
fi

if command -v clang-format-20 &>/dev/null; then
    echo "clang-format-20 already installed"
else
    echo "=== Installing clang-format-20 ==="
    sudo apt install -y clang-format-20
fi

if command -v clang-tidy-20 &>/dev/null; then
    echo "clang-tidy-20 already installed"
else
    echo "=== Installing clang-tidy-20 ==="
    sudo apt install -y clang-tidy-20
fi
