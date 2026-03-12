#!/bin/bash

if command -v lazygit &>/dev/null; then
    echo "lazygit already installed"
    exit 0
fi

echo "=== Installing lazygit ==="
LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
ARCH=$(dpkg --print-architecture)
[ "$ARCH" = "amd64" ] && ARCH="x86_64" || ARCH="arm64"
curl -fLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz"
tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
sudo mv /tmp/lazygit /usr/local/bin/
rm -f /tmp/lazygit.tar.gz
