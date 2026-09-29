#!/bin/sh
# Per-pane notifications. A marker file in the state dir arms a pane and holds
# its mode: "once" (disarm after notifying), "sticky" (keep notifying until
# toggled off or the pane closes), or "fired" (sticky, waiting for the agent to
# work again so done -> idle does not notify twice). The sidebar shows it via
# the $watch pane token.
set -eu
herdr=${HERDR_BIN_PATH:-herdr}
dir="$HERDR_PLUGIN_STATE_DIR/watched"
mkdir -p "$dir"

mark() { "$herdr" pane report-metadata "$1" --source noah.watch --token "watch=$2" >/dev/null 2>&1 || true; }
unmark() { rm -f "$dir/$1"; "$herdr" pane report-metadata "$1" --source noah.watch --clear-token watch >/dev/null 2>&1 || true; }

notify() {
  if command -v terminal-notifier >/dev/null; then
    # click: bring kitty forward and focus the pane that finished
    terminal-notifier -title "$1" -message "$2" -sound Glass -group "herdr-watch-$3" \
      -activate net.kovidgoyal.kitty \
      -execute "HERDR_SOCKET_PATH='${HERDR_SOCKET_PATH:-}' '$herdr' agent focus '$3'" >/dev/null
  else
    notify-send "$1" "$2" 2>/dev/null || true
  fi
}

case "$1" in
  reset)  # metadata tokens do not survive a server restart, so neither do markers
    rm -f "$dir"/* ;;
  once|sticky)  # same mode again turns it off; the other mode switches
    pane=${HERDR_PANE_ID:?no focused pane}
    cur=$(cat "$dir/$pane" 2>/dev/null || true); [ "$cur" = fired ] && cur=sticky
    if [ "$cur" = "$1" ]; then unmark "$pane"; exit 0; fi
    echo "$1" > "$dir/$pane"
    if [ "$1" = once ]; then mark "$pane" "👀"; else mark "$pane" "📡"; fi ;;
  event)
    ev=$(printf '%s' "${HERDR_PLUGIN_EVENT_JSON:-}" | jq -r '[.data.pane_id // "", .data.agent_status // ""] | @tsv')
    pane=${ev%%	*}; status=${ev#*	}
    [ -n "$pane" ] && [ -e "$dir/$pane" ] || exit 0
    case "${HERDR_PLUGIN_EVENT:-}" in pane.closed|pane_closed|pane.exited|pane_exited) unmark "$pane"; exit 0 ;; esac
    mode=$(cat "$dir/$pane")
    case "$status" in
      working) [ "$mode" = fired ] && echo sticky > "$dir/$pane"; exit 0 ;;
      *) [ "$mode" = fired ] && exit 0 ;;
    esac
    case "$status" in
      done|idle) msg="Finished" ;;
      blocked)   msg="Needs your input" ;;
      *) exit 0 ;;
    esac
    title=$("$herdr" pane get "$pane" 2>/dev/null | jq -r '.result.pane | .terminal_title_stripped // .agent // "agent"')
    if [ "$mode" = once ]; then unmark "$pane"; else echo fired > "$dir/$pane"; fi
    notify "$title" "$msg" "$pane" ;;
esac
