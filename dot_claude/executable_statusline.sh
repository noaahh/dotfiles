#!/bin/sh
# Claude Code status line: model, context tokens used / window size (percent),
# then prompt cache state: expiry time while warm, rebuild cost once cold.
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
  | "\(.model.display_name) · \($used | human) / \($size | human) (\($used * 100 / $size | floor)%)" as $ctx
  | .prompt_cache as $pc
  | if ($pc == null) or (($pc.requests // 0) == 0) then $ctx
    else
      (if ($pc.warm and (($pc.expires_at // 0) > now))
         then "cache until \($pc.expires_at | strflocaltime("%H:%M"))"
         else "cache cold, rebuild \(($pc.recache_tokens_if_cold // $used) | human)" end) as $state
      | ([$ctx, $state]
         + (if $pc.hit_ratio != null then ["hit \($pc.hit_ratio * 100 | round)%"] else [] end)
         + (if ($pc.misses // 0) > 0 then ["\($pc.misses) miss\(if $pc.misses == 1 then "" else "es" end)"] else [] end))
      | join(" · ")
    end
'
