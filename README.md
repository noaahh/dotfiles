# dotfiles

Configuration and provisioning for my macOS machines, managed with
[chezmoi](https://chezmoi.io). This repo owns the whole lifecycle: a fresh
machine bootstraps from it, and an existing machine reconciles against it on
every `chezmoi apply`.

## Bootstrap a fresh machine

```shell
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --use-builtin-git true noaahh
```

That single command installs chezmoi, clones this repo, and applies it. On the
way it:

- installs Xcode Command Line Tools and Homebrew (`run_once_` script)
- installs everything in the `Brewfile` via `brew bundle` (`run_onchange_`
  script, reruns whenever the Brewfile changes)
- clones the [zap](https://github.com/zap-zsh/zap) zsh plugin manager as a
  chezmoi external
- writes the dotfiles themselves
- applies macOS defaults (animations, key repeat, Finder, screenshots), see
  below

## macOS defaults

`~/.local/bin/macos-defaults` strips the system animations that add latency
without adding information and tunes the keyboard for a tiling-WM setup.
chezmoi reruns it whenever the script changes; it is idempotent and safe to
run by hand:

```shell
macos-defaults            # apply
macos-defaults --revert   # back to stock
```

The `NSGlobalDomain` keys are read at app launch, so log out and back in for
them to fully take hold.

## Machine-specific opt-ins

Anything that identifies a specific machine, network, or person stays out of
this repo. Machines opt into optional capabilities via flags under `[data]` in
the local, uncommitted `~/.config/chezmoi/chezmoi.toml`, e.g. `collie = true`.

## Layout

- `Brewfile`: packages, casks, fonts, and VS Code extensions; validated by CI
- `.chezmoiscripts/`: install and configure scripts, kept out of the home
  directory
- `.chezmoiexternal.toml`: externally sourced repos (zap)
- `dot_*`, `private_*`: the managed dotfiles
