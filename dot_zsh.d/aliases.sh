#!/bin/zsh


# Prefer GNU tools over BSD ones (macOS brew names; Linux already has them)
(( $+commands[gsed] )) && alias sed="gsed"
(( $+commands[gawk] )) && alias awk="gawk"

# Jump to the chezmoi source repo, where the dotfiles actually live.
# Resolved at runtime rather than hardcoded, so it survives a different
# CHEZMOI_SOURCE_DIR or a non-default install.
alias cz='cd "$(chezmoi source-path)"'
alias dotfiles='cd "$(chezmoi source-path)"'

# Pull the dotfiles repo and reconcile the whole machine against it:
# packages (brew bundle, mas), runtimes (mise), macOS defaults, launch
# agents, herdr plugins, dotfiles.
alias converge="chezmoi update"
