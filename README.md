# dotfiles

This repo contains the configuration to setup my machines. This is using [Chezmoi](https://chezmoi.io), the dotfile manager to setup the install.

This automated setup is currently configured for macOS machines.

## How to run

```shell
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply noaahh
```

## What's included

- **zsh** - Shell configuration with modular .zsh.d setup
- **nvim** - Neovim configuration with AstroNvim
- **vim** - Basic vim configuration
- **aerospace** - Tiling window manager for macOS
