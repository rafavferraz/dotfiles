#!/bin/bash

echo "=== Setting up dotfiles repo ==="
DOTFILES=~/code/dotfiles

if [ -d "$DOTFILES/.git" ]; then
    git -C "$DOTFILES" pull || echo "Warning: git pull failed, continuing with local copy"
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
ln -sf "$DOTFILES/claude/statusline-command.sh" ~/.claude/statusline-command.sh
ln -sfn "$DOTFILES/claude/agents" ~/.claude/agents
ln -sfn "$DOTFILES/claude/skills" ~/.claude/skills

echo "=== Setting up git credentials ==="
gh auth setup-git
