#!/usr/bin/env bash
# Pick and focus an agent.

set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"

if ! command -v fzf >/dev/null 2>&1; then
  printf 'fzf is required for agent-switcher.sh\n' >&2
  exit 1
fi

agents=$("$HERDR" agent list)
workspaces=$("$HERDR" workspace list)
tabs=$("$HERDR" tab list)

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

entries="$tmpdir/entries.tsv"

jq -rs '
  def status_rank:
      if . == "blocked" then 0
      elif . == "done" then 1
      elif . == "working" then 2
      elif . == "idle" then 3
      else 4
      end;
  def status_icon:
      if . == "blocked" then "!"
      elif . == "done" then "✓"
      elif . == "working" then "*"
      elif . == "idle" then "o"
      else "."
      end;
  .[0] as $agents
  | .[1] as $workspaces
  | .[2] as $tabs
  | ($workspaces.result.workspaces
      | map({key: .workspace_id, value: {label: (.label // "workspace"), number: (.number // 9999)}})
      | from_entries) as $workspace_by_id
  | ($tabs.result.tabs
      | map({key: .tab_id, value: {label: (.label // "tab"), number: (.number // 9999)}})
      | from_entries) as $tab_by_id
  | $agents.result.agents
  | sort_by(
      (.agent_status | status_rank),
      ($workspace_by_id[.workspace_id].number // 9999),
      ($tab_by_id[.tab_id].number // 9999),
      .pane_id
    )
  | .[]
  | ($workspace_by_id[.workspace_id].label // "workspace") as $workspace_label
  | ($workspace_by_id[.workspace_id].number // 9999) as $workspace_number
  | ($tab_by_id[.tab_id].label // "tab") as $tab_label
  | ($tab_by_id[.tab_id].number // 9999) as $tab_number
  | (.foreground_cwd // .cwd // "") as $cwd
  | ($cwd | split("/") | map(select(length > 0)) | last // "~") as $repo
  | (.agent_status // "unknown") as $status
  | (if .focused then ">" else " " end) as $focused
  | [
      (
        "\($focused) \($status | status_icon)  "
        + ($workspace_label | .[0:22])
        + "  "
        + "\($workspace_number).\($tab_number)"
        + "  "
        + ($repo | .[0:28])
        + "  "
        + ($status | .[0:10])
        + "  "
        + ($tab_label | .[0:40])
      ),
      .workspace_id,
      .tab_id,
      .pane_id
    ]
  | @tsv
' <(printf '%s' "$agents") <(printf '%s' "$workspaces") <(printf '%s' "$tabs") > "$entries"

if [[ ! -s "$entries" ]]; then
  printf 'no agents\n' >&2
  exit 0
fi

selection=$(
  cut -f1 "$entries" \
    | fzf \
      --ansi \
      --no-sort \
      --prompt='agents> ' \
      --height='80%' \
      --layout=reverse \
      --border \
      --header='enter: focus, esc: cancel'
)

[[ -n "${selection:-}" ]] || exit 0

row=$(awk -F'\t' -v selected="$selection" '$1 == selected { print; exit }' "$entries")
[[ -n "$row" ]] || exit 0

workspace_id=$(printf '%s' "$row" | awk -F'\t' '{ print $2 }')
tab_id=$(printf '%s' "$row" | awk -F'\t' '{ print $3 }')
pane_id=$(printf '%s' "$row" | awk -F'\t' '{ print $4 }')

"$HERDR" workspace focus "$workspace_id" >/dev/null
"$HERDR" tab focus "$tab_id" >/dev/null
"$HERDR" agent focus "$pane_id" >/dev/null
