#!/usr/bin/env bash
# Focus the next agent that needs attention.
#
# Blocked agents rotate via an anchor token, since visiting one does not
# change its status. Done agents need no rotation state: focusing a done
# pane marks it seen and herdr flips it to idle, so the queue drains by
# itself; newest completion first. With nothing pending, working and idle
# agents rotate in workspace/tab order. Errors are logged to
# next-pending.log and surfaced as a herdr notification.

set -uo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
SOCKET="${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}"
LOG="${HERDR_STATE_DIR:-$HOME/.config/herdr}/next-pending.log"
SOURCE_ID="next-pending"
TOKEN="np-last"

log() { printf '%s %s\n' "$(date '+%F %T')" "$1" >> "$LOG"; }

fail() {
  log "$1"
  "$HERDR" notification show "next-pending: $1" --sound none >/dev/null 2>&1
  exit 1
}

fetch() {
  local out code
  if ! out=$("$HERDR" "$@" 2>&1); then
    code=$(printf '%s' "$out" | jq -r '.error.code // "unknown"' 2>/dev/null) || code=unknown
    fail "herdr $* failed ($code)"
  fi
  printf '%s' "$out"
}

# Sidebar projection: while a pending queue exists, show only blocked/done
# agents ordered by attention; cleared when the queue drains. Sent over the
# raw socket (ndjson) because agent.view has no CLI verb yet; best-effort.
view_update() {
  command -v nc >/dev/null 2>&1 || return 0
  [[ -S "$SOCKET" ]] || return 0
  local req
  if [[ "${1:-}" == "clear" ]]; then
    req='{"id":"np:view","method":"agent.view.clear","params":{"source":"'"$SOURCE_ID"'"}}'
  else
    req='{"id":"np:view","method":"agent.view.set","params":{"source":"'"$SOURCE_ID"'","label":"pending","filter":{"op":"in","field":"status","values":["blocked","done"]},"sort":[{"field":"attention","order":"asc"},{"field":"state_change_seq","order":"desc"}]}}'
  fi
  printf '%s\n' "$req" | nc -U -w 1 "$SOCKET" >/dev/null 2>&1
}

agents=$(fetch agent list) || exit 1
workspaces=$(fetch workspace list) || exit 1
tabs=$(fetch tab list) || exit 1

focused_pane=$(printf '%s' "$agents" | jq -r '
  first(.result.agents[] | select(.focused == true) | .pane_id) // ""
')

anchor_holder=$(printf '%s' "$agents" | jq -r --arg token "$TOKEN" '
  first(.result.agents[] | select((.tokens // {}) | (try has($token) catch false)) | .pane_id) // ""
')

pending_count=$(printf '%s' "$agents" | jq -r '
  [.result.agents[] | select(.agent_status == "blocked" or .agent_status == "done")] | length
')

focus_pane() {
  local pane="$1" ws="$2" tab="$3" focused_now
  # 0.7.5 agent focus brings workspace and tab along; the explicit
  # focus calls remain as a fallback in case that ever regresses.
  "$HERDR" agent focus "$pane" >/dev/null 2>&1
  focused_now=$("$HERDR" agent list 2>/dev/null | jq -r '
    first(.result.agents[] | select(.focused == true) | .pane_id) // ""
  ')
  if [[ "$focused_now" != "$pane" ]]; then
    "$HERDR" workspace focus "$ws" >/dev/null 2>&1
    "$HERDR" tab focus "$tab" >/dev/null 2>&1
    "$HERDR" agent focus "$pane" >/dev/null 2>&1
  fi
}

finish() {
  local pane="$1" ws="$2" tab="$3" move_anchor="$4"
  focus_pane "$pane" "$ws" "$tab"
  if [[ "$move_anchor" == anchor ]]; then
    if [[ -n "$anchor_holder" && "$anchor_holder" != "$pane" ]]; then
      "$HERDR" pane report-metadata "$anchor_holder" --source "$SOURCE_ID" --clear-token "$TOKEN" >/dev/null 2>&1
    fi
    "$HERDR" pane report-metadata "$pane" --source "$SOURCE_ID" --token "$TOKEN=1" >/dev/null 2>&1
  fi
  if [[ "$pending_count" -gt 1 ]]; then
    view_update set &
  else
    view_update clear &
  fi
  exit 0
}

# Newest done agent, if any: focus it and let herdr's seen semantics
# retire it from the queue. Blocked agents still take priority below.
newest_done=$(printf '%s' "$agents" | jq -r '
  [.result.agents[] | select(.agent_status == "done")]
  | sort_by(-(.state_change_seq // 0))
  | first // empty
  | [.pane_id, .workspace_id, .tab_id] | @tsv
')

# Rotation pool: blocked agents when any exist, else working/idle,
# ordered by workspace, tab, pane. Fields: pane_id, workspace_id, tab_id.
rotation=$(jq -rs '
  .[0] as $agents
  | .[1] as $workspaces
  | .[2] as $tabs
  | ($workspaces.result.workspaces | map({key: .workspace_id, value: (.number // 9999)}) | from_entries) as $workspace_order
  | ($tabs.result.tabs | map({key: .tab_id, value: (.number // 9999)}) | from_entries) as $tab_order
  | [$agents.result.agents[] | select(.agent_status == "blocked")] as $blocked
  | (if ($blocked | length) > 0 then $blocked
     else [$agents.result.agents[]
       | select(.agent_status == "working" or .agent_status == "idle")]
     end)
  | sort_by(
      ($workspace_order[.workspace_id] // 9999),
      ($tab_order[.tab_id] // 9999),
      .pane_id
    )
  | .[]
  | [.pane_id, .workspace_id, .tab_id, .agent_status]
  | @tsv
' <(printf '%s' "$agents") <(printf '%s' "$workspaces") <(printf '%s' "$tabs"))

has_blocked=$(printf '%s\n' "$rotation" | awk -F'\t' 'NR == 1 && $4 == "blocked" { print "yes" }')

if [[ -n "$rotation" && "$has_blocked" == "yes" ]]; then
  : # blocked agents rotate below
elif [[ -n "$newest_done" ]]; then
  done_ws=$(printf '%s' "$newest_done" | awk -F'\t' '{ print $2 }')
  done_tab=$(printf '%s' "$newest_done" | awk -F'\t' '{ print $3 }')
  done_pane=$(printf '%s' "$newest_done" | awk -F'\t' '{ print $1 }')
  finish "$done_pane" "$done_ws" "$done_tab" noanchor
fi

[[ -z "$rotation" ]] && { view_update clear & exit 0; }

if [[ -n "$focused_pane" && "$focused_pane" != "$anchor_holder" ]] \
  && printf '%s\n' "$rotation" | awk -F'\t' -v cur="$focused_pane" '$1 == cur { found = 1 } END { exit found ? 0 : 1 }'; then
  anchor="$focused_pane"
else
  anchor="$anchor_holder"
fi

next_after() {
  local anchor_pane="$1"
  printf '%s\n' "$rotation" | awk -F'\t' -v anchor="$anchor_pane" '
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

rotation_count=$(printf '%s\n' "$rotation" | awk 'NF { count++ } END { print count + 0 }')
if [[ "$rotation_count" -gt 1 && "$next_pane" == "$focused_pane" ]]; then
  next_pane=$(next_after "$next_pane")
fi

[[ -z "$next_pane" ]] && exit 0

next_row=$(printf '%s\n' "$rotation" | awk -F'\t' -v p="$next_pane" '$1 == p { print; exit }')
next_ws=$(printf '%s' "$next_row" | awk -F'\t' '{ print $2 }')
next_tab=$(printf '%s' "$next_row" | awk -F'\t' '{ print $3 }')

finish "$next_pane" "$next_ws" "$next_tab" anchor
