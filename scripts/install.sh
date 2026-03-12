#!/bin/bash

OS="$(uname -s)"

echo "=== Installing packages ==="
if [ "$OS" = "Darwin" ]; then
    brew install --cask kitty zed docker || true
    brew install git gh curl fish bat btop htop lazygit tree yazi starship || true
    brew install --cask font-jetbrains-mono-nerd-font || true
elif [ "$OS" = "Linux" ]; then
    sudo apt update
    sudo apt install -y git gh curl kitty fish bat btop htop tree || true
    # lazygit — download pre-built binary
    if ! command -v lazygit &>/dev/null; then
        LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
        ARCH=$(dpkg --print-architecture)
        [ "$ARCH" = "amd64" ] && ARCH="x86_64" || ARCH="arm64"
        curl -fLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
        sudo mv /tmp/lazygit /usr/local/bin/
        rm -f /tmp/lazygit.tar.gz
    fi
    # starship — download pre-built binary
    if ! command -v starship &>/dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
    # yazi — download pre-built binary
    if ! command -v yazi &>/dev/null; then
        curl -fLo /tmp/yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
        unzip -o /tmp/yazi.zip -d /tmp/yazi
        sudo mv /tmp/yazi/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/
        rm -rf /tmp/yazi /tmp/yazi.zip
    fi
    FONT_DIR=~/.local/share/fonts
    mkdir -p "$FONT_DIR"
    curl -fLo "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" \
        https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf
    fc-cache -f
    # zed — download pre-built binary
    if ! command -v zed &>/dev/null; then
        curl -sS https://zed.dev/install.sh | sh
    fi
    # nvidia driver — auto-detect and install recommended driver
    if ! command -v nvidia-smi &>/dev/null && command -v lspci &>/dev/null && lspci | grep -qi nvidia; then
        sudo apt install -y ubuntu-drivers-common
        sudo ubuntu-drivers install
        echo "NVIDIA driver installed. Reboot and re-run this script for nvidia-container-toolkit."
    fi
    # docker — install via convenience script
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker "$USER"
    fi
    # nvidia-container-toolkit — only if GPU is present
    if command -v nvidia-smi &>/dev/null && ! dpkg -s nvidia-container-toolkit &>/dev/null 2>&1; then
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
            | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
            | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        sudo apt update
        sudo apt install -y nvidia-container-toolkit
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
    fi
fi

echo "=== Authenticating with GitHub ==="
if ! gh auth status &>/dev/null; then
    gh auth login
fi

echo "=== Installing Claude Code ==="
if ! command -v claude &>/dev/null; then
    curl -fsSL https://claude.ai/install.sh | bash
fi

echo "=== Configuring fish shell ==="
FISH_PATH="$(which fish)"
if [ "$OS" = "Darwin" ]; then
    fish -c "fish_add_path /opt/homebrew/bin" 2>/dev/null || true
fi
if [ -n "$FISH_PATH" ] && ! grep -q "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi
if [ -n "$FISH_PATH" ] && [ "$SHELL" != "$FISH_PATH" ]; then
    chsh -s "$FISH_PATH"
fi

echo "=== Installing yazi flavor ==="
if command -v ya &>/dev/null; then
    ya pkg add bennyyip/gruvbox-dark || true
fi

echo "=== Setting up dotfiles repo ==="
DOTFILES=~/code/dotfiles

if [ -d "$DOTFILES/.git" ]; then
    git -C "$DOTFILES" pull
elif [ -d "$DOTFILES" ]; then
    git clone https://github.com/rafavferraz/dotfiles.git /tmp/dotfiles-clone
    cp -a /tmp/dotfiles-clone/. "$DOTFILES/"
    rm -rf /tmp/dotfiles-clone
else
    git clone https://github.com/rafavferraz/dotfiles.git "$DOTFILES"
fi

echo "=== Setting up symlinks ==="

mkdir -p ~/.config/kitty
mkdir -p ~/.config/fish
mkdir -p ~/.config/yazi
mkdir -p ~/.config/zed
mkdir -p ~/.claude

ln -sf "$DOTFILES/kitty/kitty.conf" ~/.config/kitty/kitty.conf
ln -sf "$DOTFILES/kitty/current-theme.conf" ~/.config/kitty/current-theme.conf
ln -sf "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish
ln -sf "$DOTFILES/git/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES/yazi/yazi.toml" ~/.config/yazi/yazi.toml
ln -sf "$DOTFILES/yazi/theme.toml" ~/.config/yazi/theme.toml
ln -sf "$DOTFILES/starship/starship.toml" ~/.config/starship.toml
ln -sf "$DOTFILES/zed/settings.json" ~/.config/zed/settings.json
ln -sf "$DOTFILES/claude/settings.json" ~/.claude/settings.json

echo "=== Setting up git credentials ==="
gh auth setup-git

echo "=== Done! ==="
echo "Restart Kitty to apply changes."
echo "Run 'kitty +kitten themes' to pick a theme."
