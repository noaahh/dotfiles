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

## Machine-specific opt-ins

Anything that identifies a specific machine, network, or person stays out of
this repo. Machines opt into optional capabilities via flags under `[data]` in
the local, uncommitted `~/.config/chezmoi/chezmoi.toml`, e.g. `collie = true`.

## Layout

- `Brewfile`: packages, casks, fonts, and VS Code extensions; validated by CI
- `.chezmoiscripts/`: setup scripts, kept out of the home directory
- `.chezmoiexternal.toml`: repos cloned by chezmoi (zap, plus sources for
  tools built locally)
- `dot_*`, `private_*`: the managed dotfiles
