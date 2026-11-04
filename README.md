# dotfiles

Configuration and provisioning for my macOS machines, managed with
[chezmoi](https://chezmoi.io). This repo owns the whole lifecycle: a fresh
machine bootstraps from it, and an existing machine reconciles against it.

## Bootstrap a fresh machine

```shell
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --use-builtin-git true noaahh
```

This installs chezmoi, clones the repo, writes the dotfiles and runs every
setup step. Each step is a script in `.chezmoiscripts/`, numbered in run
order; `run_onchange_` scripts rerun whenever their content or input changes.

## Keep a machine in sync

```shell
converge   # chezmoi update: pull, then apply
```

## macOS defaults

```shell
macos-defaults            # apply
macos-defaults --revert   # back to stock
```

Log out and back in for the `NSGlobalDomain` keys to take hold.

## Installed by hand

[Insomnia](https://github.com/krishhgg/Insomnia) keeps the Mac awake with the
lid closed. It has no Homebrew cask and its installer needs a password for a
sudoers rule limited to four `pmset` commands, so it is built from a pinned,
reviewed tag:

```shell
git clone --branch <tag> --depth 1 https://github.com/krishhgg/Insomnia.git ~/dev/misc/Insomnia
~/dev/misc/Insomnia/scripts/install.sh      # uninstall.sh in the same folder removes it
```

## Machine-specific opt-ins

Anything that identifies a specific machine, network, or person stays out of
this repo. Machines opt into optional capabilities via flags under `[data]` in
the local, uncommitted `~/.config/chezmoi/chezmoi.toml`, e.g. `ovis = true`.

## Layout

- `Brewfile`: packages, casks, and fonts; validated by CI
- `.chezmoiscripts/`: setup scripts, kept out of the home directory
- `.chezmoiexternal.toml`: repos cloned by chezmoi (zap, plus sources for
  tools built locally)
- `dot_*`, `private_*`: the managed dotfiles
