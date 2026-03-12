#!/bin/bash

if command -v docker &>/dev/null; then
    echo "docker already installed"
    exit 0
fi

echo "=== Installing docker ==="
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"
