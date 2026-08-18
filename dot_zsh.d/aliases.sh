#!/bin/zsh

alias db="cd ~/DB && nvim ~/DB/index.md"

# Prefer GNU tools over BSD ones

# GNU sed
alias sed="gsed"
alias awk="gawk"

# Jump to the chezmoi source repo, where the dotfiles actually live.
# Resolved at runtime rather than hardcoded, so it survives a different
# CHEZMOI_SOURCE_DIR or a non-default install.
alias cz='cd "$(chezmoi source-path)"'
alias dotfiles='cd "$(chezmoi source-path)"'
