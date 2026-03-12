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

# install nvidia-container-toolkit if not present (requires docker)
if command -v docker &>/dev/null && ! dpkg -s nvidia-container-toolkit &>/dev/null 2>&1; then
    echo "=== Installing nvidia-container-toolkit ==="
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
        | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
        | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt update
    sudo apt install -y nvidia-container-toolkit
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker
fi
