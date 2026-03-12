#!/bin/bash

if ! command -v yazi &>/dev/null; then
    echo "=== Installing yazi ==="
    curl -fLo /tmp/yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
    unzip -o /tmp/yazi.zip -d /tmp/yazi
    sudo mv /tmp/yazi/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
    rm -rf /tmp/yazi /tmp/yazi.zip
fi

echo "=== Installing yazi flavor ==="
if command -v ya &>/dev/null; then
    ya pkg add bennyyip/gruvbox-dark || true
fi
