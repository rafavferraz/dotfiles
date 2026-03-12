# Dotfiles

Personal configuration files synced across Linux and macOS machines.

## What's included

- **kitty** — terminal emulator config + theme
- **fish** — shell config
- **git** — global gitconfig
- **starship** — prompt config
- **yazi** — file manager config + theme
- **zed** — editor settings
- **claude** — Claude Code settings
- **scripts** — setup and utility scripts

## New machine setup

```bash
git clone https://github.com/rafavferraz/dotfiles.git ~/code/dotfiles
bash ~/code/dotfiles/setup.sh
```

This creates the folder structure, installs packages, symlinks configs, and sets fish as the default shell.

### NVIDIA GPU machines (Linux)

On machines with an NVIDIA GPU, the script requires two runs with a reboot in between:

1. **First run** — installs everything including the NVIDIA driver
2. **Reboot** — needed for the driver to load
3. **Second run** — detects the GPU via `nvidia-smi` and installs `nvidia-container-toolkit`

```bash
bash ~/code/dotfiles/setup.sh
sudo reboot
bash ~/code/dotfiles/setup.sh
```

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
