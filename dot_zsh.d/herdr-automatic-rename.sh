for _herdr_automatic_rename_hook in ${HOME}/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
  source "$_herdr_automatic_rename_hook"
  break
done
unset _herdr_automatic_rename_hook
