#!/bin/bash

OS="$(uname -s)"

echo "=== Installing packages ==="
if [ "$OS" = "Darwin" ]; then
    brew install --cask kitty || true
    brew install git curl fish bat htop tree yazi starship || true
    brew install --cask font-jetbrains-mono-nerd-font || true
elif [ "$OS" = "Linux" ]; then
    sudo apt update
    sudo apt install -y git curl kitty fish bat htop tree || true
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
fi

echo "=== Configuring fish shell ==="
if [ "$OS" = "Darwin" ]; then
    fish -c "fish_add_path /opt/homebrew/bin" 2>/dev/null || true
fi

echo "=== Setting up symlinks ==="
DOTFILES=~/code/dotfiles

mkdir -p ~/.config/kitty
mkdir -p ~/.config/fish
mkdir -p ~/.config/yazi

ln -sf "$DOTFILES/kitty/kitty.conf" ~/.config/kitty/kitty.conf
ln -sf "$DOTFILES/kitty/current-theme.conf" ~/.config/kitty/current-theme.conf
ln -sf "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish
ln -sf "$DOTFILES/git/.gitconfig" ~/.gitconfig
ln -sf "$DOTFILES/yazi/yazi.toml" ~/.config/yazi/yazi.toml
ln -sf "$DOTFILES/starship/starship.toml" ~/.config/starship.toml

echo "=== Done! ==="
echo "Restart Kitty to apply changes."
echo "Run 'kitty +kitten themes' to pick a theme."
