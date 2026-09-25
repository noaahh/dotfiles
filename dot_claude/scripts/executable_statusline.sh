#!/bin/bash
payload="$(cat)"

tsv="$(printf '%s' "$payload" | jq -r '
  [
    (.context_window.context_window_size // 0),
    (.effort.level // "default"),
    (if .thinking.enabled then "on" else "off" end),
    (.prompt_cache.warm // false),
    (.prompt_cache.hit_ratio // -1),
    (.prompt_cache.expires_at // 0),
    (.prompt_cache.misses // 0),
    (.session_id // "")
  ] | @tsv
')"
IFS=$'\t' read -r ctx_size effort thinking cache_warm cache_hit_ratio cache_expires_at cache_misses session_id <<< "$tsv"

if [ "$ctx_size" -ge 1000000 ] 2>/dev/null; then
  ctx_label="$((ctx_size / 1000000))M"
elif [ "$ctx_size" -ge 1000 ] 2>/dev/null; then
  ctx_label="$((ctx_size / 1000))K"
else
  ctx_label="${ctx_size}"
fi

line1="$(printf 'WINDOW %s  EFFORT %s  THINKING %s  %s' \
  "$ctx_label" "$effort" "$thinking" "$session_id")"

# Claude Code reports real cache stats (not estimated) in .prompt_cache —
# claude-statusline never reads this field, so surface it ourselves.
if [ "$(awk "BEGIN{print ($cache_hit_ratio >= 0)}")" = "1" ]; then
  cache_pct="$(awk "BEGIN{printf \"%.0f\", $cache_hit_ratio * 100}")"
  now="$(date +%s)"
  remaining=$((cache_expires_at - now))
  if [ "$remaining" -gt 0 ] 2>/dev/null; then
    if [ "$remaining" -ge 3600 ]; then
      ttl_label="$((remaining / 3600))h$(((remaining % 3600) / 60))m"
    else
      ttl_label="$((remaining / 60))m"
    fi
  else
    ttl_label="expired"
  fi

  RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; DIM='\033[2m'; RESET='\033[0m'
  if [ "$cache_warm" != "true" ] || [ "$remaining" -le 0 ] 2>/dev/null; then
    color="$RED"
  elif [ "$cache_misses" -gt 0 ] 2>/dev/null || [ "$cache_pct" -lt 90 ] 2>/dev/null; then
    color="$YELLOW"
  else
    color="$GREEN"
  fi

  cache_line="$(printf "${color}CACHE %s%%${DIM} · %s req, %s miss · expires %s${RESET}" \
    "$cache_pct" "$(printf '%s' "$payload" | jq -r '.prompt_cache.requests // 0')" \
    "$cache_misses" "$ttl_label")"
fi

output="$line1"
[ -n "$cache_line" ] && output="$output"$'\n'"$cache_line"
printf '%s\n' "$output"
