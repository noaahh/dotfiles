#!/bin/zsh

# Right-prompt extras on top of zap-prompt: command duration (for slow
# commands) and the active AWS profile, since that's toggled often via
# aws-profile.
zmodload zsh/datetime

typeset -g _prompt_cmd_start=0
# Pre-baked %-sequence segments, built in _prompt_precmd. Kept as whole
# segments (rather than assembling %F{color} inline inside ${VAR:+...} in
# RPROMPT) because zsh's brace-matching for ${VAR:+...} breaks when the
# replacement text itself contains braces, like %F{yellow} does.
typeset -g _prompt_duration_seg=""
typeset -g _prompt_aws_seg=""

_prompt_preexec() {
  _prompt_cmd_start=$EPOCHSECONDS
}

_prompt_precmd() {
  local elapsed=0
  if (( _prompt_cmd_start > 0 )); then
    elapsed=$(( EPOCHSECONDS - _prompt_cmd_start ))
  fi
  _prompt_cmd_start=0

  if (( elapsed >= 5 )); then
    local h=$(( elapsed / 3600 )) m=$(( (elapsed % 3600) / 60 )) s=$(( elapsed % 60 )) dur
    if (( h > 0 )); then
      dur="${h}h${m}m${s}s"
    elif (( m > 0 )); then
      dur="${m}m${s}s"
    else
      dur="${s}s"
    fi
    _prompt_duration_seg="%F{yellow}${dur}%f"
  else
    _prompt_duration_seg=""
  fi

  if [[ -n "$AWS_PROFILE" ]]; then
    _prompt_aws_seg="%F{cyan}${AWS_PROFILE}%f"
  else
    _prompt_aws_seg=""
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _prompt_preexec
add-zsh-hook precmd _prompt_precmd

RPROMPT='${_prompt_duration_seg}${_prompt_duration_seg:+ }${_prompt_aws_seg}'
