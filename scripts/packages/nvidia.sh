#!/bin/bash

# skip if no NVIDIA GPU detected
if ! command -v lspci &>/dev/null || ! lspci | grep -qi nvidia; then
    exit 0
fi

# install driver if not present
if ! command -v nvidia-smi &>/dev/null; then
    echo "=== Installing NVIDIA driver ==="
    sudo apt install -y ubuntu-drivers-common
    sudo ubuntu-drivers install
    echo "NVIDIA driver installed. Reboot and re-run setup.sh for nvidia-container-toolkit."
    exit 0
fi
