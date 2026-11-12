#!/bin/sh
# Claude Code status line: model, context tokens used / window size (percent).
jq -r '
  def human:
    if . >= 1000000 then (. / 100000 | floor / 10 | tostring) + "M"
    elif . >= 1000 then (. / 100 | floor / 10 | tostring) + "k"
    else tostring end
    | sub("\\.0(?<u>[kM])$"; "\(.u)");
  .context_window as $cw
  | ($cw.current_usage // {}) as $u
  | (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) as $used
  | ($cw.context_window_size // 200000) as $size
  | "\(.model.display_name) · \($used | human) / \($size | human) (\($used * 100 / $size | floor)%)"
'
