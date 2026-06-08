#!/usr/bin/env bash
# Focus the next agent that likely needs attention.

set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
STATE_DIR="${HERDR_STATE_DIR:-$HOME/.config/herdr}"
STATE_FILE="$STATE_DIR/next-pending-state"

agents=$("$HERDR" agent list)
workspaces=$("$HERDR" workspace list)
tabs=$("$HERDR" tab list)

notify() {
  osascript -e "display notification \"$1\" with title \"herdr\"" 2>/dev/null || true
}

focused_pane=$(printf '%s' "$agents" | jq -r '
  first(.result.agents[] | select(.focused == true) | .pane_id) // ""
')

build_candidates() {
  local status="$1"
  jq -rs --arg status "$status" '
  .[0] as $agents
  | .[1] as $workspaces
  | .[2] as $tabs
  | ($workspaces.result.workspaces | map({key: .workspace_id, value: (.number // 9999)}) | from_entries) as $workspace_order
  | ($tabs.result.tabs | map({key: .tab_id, value: (.number // 9999)}) | from_entries) as $tab_order
  | $agents.result.agents
  | map(select(.agent_status == $status))
  | sort_by(
      if .agent_status == "blocked" then 0 elif .agent_status == "working" then 1 else 2 end,
      ($workspace_order[.workspace_id] // 9999),
      ($tab_order[.tab_id] // 9999),
      .pane_id
    )
  | .[]
  | [.pane_id, .workspace_id, .tab_id, .agent_status, (.agent // "agent"), (.foreground_cwd // .cwd // "")]
  | @tsv
  ' <(printf '%s' "$agents") <(printf '%s' "$workspaces") <(printf '%s' "$tabs")
}

# Fields: pane_id, workspace_id, tab_id, status, agent, cwd
candidates=$(build_candidates blocked)

if [[ -z "$candidates" ]]; then
  candidates=$(build_candidates working)
fi

if [[ -z "$candidates" ]]; then
  candidates=$(build_candidates idle)
fi

if [[ -z "$candidates" ]]; then
  notify "no agents"
  exit 0
fi

last_key=""
if [[ -f "$STATE_FILE" ]]; then
  last_key=$(cat "$STATE_FILE" 2>/dev/null || true)
fi

if [[ -n "$focused_pane" && "$focused_pane" != "$last_key" ]] \
  && printf '%s\n' "$candidates" | awk -F'\t' -v cur="$focused_pane" '$1 == cur { found = 1 } END { exit found ? 0 : 1 }'; then
  anchor="$focused_pane"
else
  anchor="$last_key"
fi

next_after() {
  local anchor_pane="$1"
  printf '%s\n' "$candidates" | awk -F'\t' -v anchor="$anchor_pane" '
  BEGIN { first = ""; picked = ""; found = 0 }
  {
    if (first == "") first = $1
    if (found && picked == "") {
      picked = $1
      exit
    }
    if ($1 == anchor) found = 1
  }
  END {
    if (picked != "") print picked
    else print first
  }
'
}

next_pane=$(next_after "$anchor")

candidate_count=$(printf '%s\n' "$candidates" | awk 'NF { count++ } END { print count + 0 }')
if [[ "$candidate_count" -gt 1 && "$next_pane" == "$focused_pane" ]]; then
  next_pane=$(next_after "$next_pane")
fi

[[ -z "$next_pane" ]] && exit 0

next_row=$(printf '%s\n' "$candidates" | awk -F'\t' -v p="$next_pane" '$1 == p { print; exit }')
next_ws=$(printf '%s' "$next_row" | awk -F'\t' '{ print $2 }')
next_tab=$(printf '%s' "$next_row" | awk -F'\t' '{ print $3 }')
next_agent=$(printf '%s' "$next_row" | awk -F'\t' '{ print $5 }')
next_cwd=$(printf '%s' "$next_row" | awk -F'\t' '{ print $6 }')
next_repo="${next_cwd##*/}"
[[ -z "$next_repo" ]] && next_repo="~"

mkdir -p "$STATE_DIR"
printf '%s\n' "$next_pane" > "$STATE_FILE"

"$HERDR" workspace focus "$next_ws" >/dev/null
"$HERDR" tab focus "$next_tab" >/dev/null
"$HERDR" agent focus "$next_pane" >/dev/null
