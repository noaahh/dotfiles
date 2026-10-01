#!/bin/sh
# alt+a: jump to an agent that needs you (blocked first, then done, oldest
# first); otherwise cycle through the working agents, or all agents if none
# are working, wrapping around.
herdr=${HERDR_BIN_PATH:-herdr}
target=$("$herdr" agent list 2>/dev/null | jq -r '
  .result.agents as $a
  | ([$a[] | select(.focused | not) | select(.agent_status == "blocked" or .agent_status == "done")]
     | sort_by((if .agent_status == "blocked" then 0 else 1 end), .state_change_seq) | .[0].pane_id)
  // (([$a[] | select(.agent_status == "working")] | if length > 0 then . else $a end) as $w
      | ($w | map(.focused) | index(true)) as $i
      | $w[if $i == null then 0 else ($i + 1) % ($w | length) end].pane_id)
  // empty')
[ -n "$target" ] && exec "$herdr" agent focus "$target"
