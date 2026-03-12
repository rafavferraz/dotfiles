# Dotfiles

Personal configuration files synced across Linux and macOS machines.

## What's included

- **kitty** — terminal emulator config + theme
- **fish** — shell config
- **git** — global gitconfig
- **scripts** — setup and utility scripts

## New machine setup

```bash
git clone git@github.com:youruser/dotfiles.git ~/code/dotfiles
bash ~/code/dotfiles/setup.sh
```

This creates the folder structure, installs packages, and symlinks configs.

## Syncing changes

```bash
cd ~/code/dotfiles && git pull
```

Configs update immediately since they're symlinked.

## Saving changes

```bash
cd ~/code/dotfiles
git add -A
git commit -m "description of change"
git push
```
