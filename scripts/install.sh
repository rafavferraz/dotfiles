#!/bin/bash

OS="$(uname -s)"

echo "=== Installing packages ==="
if [ "$OS" = "Darwin" ]; then
    brew install --cask kitty zed || true
    brew install git gh curl fish bat btop htop tree yazi starship || true
    brew install --cask font-jetbrains-mono-nerd-font || true
elif [ "$OS" = "Linux" ]; then
    sudo apt update
    sudo apt install -y git gh curl kitty fish bat btop htop tree || true
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

echo "=== Setting up symlinks ==="
DOTFILES=~/code/dotfiles

mkdir -p ~/.config/kitty
mkdir -p ~/.config/fish
mkdir -p ~/.config/yazi
mkdir -p ~/.config/zed
mkdir -p ~/.claude
mkdir -p ~/.ssh

ln -sf "$DOTFILES/kitty/kitty.conf" ~/.config/kitty/kitty.conf
ln -sf "$DOTFILES/kitty/current-theme.conf" ~/.config/kitty/current-theme.conf
ln -sf "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish
ln -sf "$DOTFILES/git/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES/yazi/yazi.toml" ~/.config/yazi/yazi.toml
ln -sf "$DOTFILES/yazi/theme.toml" ~/.config/yazi/theme.toml
ln -sf "$DOTFILES/starship/starship.toml" ~/.config/starship.toml
ln -sf "$DOTFILES/zed/settings.json" ~/.config/zed/settings.json
ln -sf "$DOTFILES/claude/settings.json" ~/.claude/settings.json
ln -sf "$DOTFILES/ssh/config" ~/.ssh/config

echo "=== Done! ==="
echo "Restart Kitty to apply changes."
echo "Run 'kitty +kitten themes' to pick a theme."
