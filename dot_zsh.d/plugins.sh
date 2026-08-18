# Created by Zap Installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

# plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/supercharge"
plug "zap-zsh/zap-prompt"
plug "MichaelAquilina/zsh-you-should-use"

plug "Aloxaf/fzf-tab"
plug "zap-users/zsh-syntax-highlighting"

# Up/Down arrow filters history by what's already typed, instead of just cycling.
# Must load after zsh-syntax-highlighting so matches get highlighted correctly.
plug "zsh-users/zsh-history-substring-search"
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Atuin shell history
# eval "$(atuin init zsh)"

# McFly shell history
# McFly's ^R UI defaults to a dark-terminal palette; match macOS appearance so
# it stays readable when the terminal (kitty) is in light mode.
if [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" != "Dark" ]]; then
  export MCFLY_LIGHT=TRUE
fi
eval "$(mcfly init zsh)"
