#!/bin/sh
# Per-pane notifications. A marker file in the state dir arms a pane and holds
# its mode: "once" (disarm after notifying), "sticky" (keep notifying until
# toggled off or the pane closes), or "fired" (sticky, waiting for the agent to
# work again so done -> idle does not notify twice). The sidebar shows it via
# the $watch pane token.
#
# Also run outside herdr's plugin runner: the Claude Code UserPromptSubmit hook
# calls `watch.sh prompt`, so the state dir falls back to herdr's default.
set -eu
herdr=${HERDR_BIN_PATH:-herdr}
dir="${HERDR_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/herdr/plugins/noah.watch}/watched"
away_secs=${WATCH_AWAY_SECS:-300}
mkdir -p "$dir"

mark() { "$herdr" pane report-metadata "$1" --source noah.watch --token "watch=$2" >/dev/null 2>&1 || true; }
unmark() { rm -f "$dir/$1"; "$herdr" pane report-metadata "$1" --source noah.watch --clear-token watch >/dev/null 2>&1 || true; }
toast() { "$herdr" notification show "$1" --body "$2" --sound none >/dev/null 2>&1 || true; }

notify() {
  # already looking at herdr in kitty: an in-app toast is enough
  front=$(lsappinfo info -only bundleid "$(lsappinfo front 2>/dev/null)" 2>/dev/null || true)
  if case "$front" in *net.kovidgoyal.kitty*) true ;; *) false ;; esac; then
    toast "$1" "$2"
  elif command -v terminal-notifier >/dev/null; then
    # click: bring kitty forward and focus the pane that finished
    terminal-notifier -title "$1" -message "$2" -sound Glass -group "herdr-watch-$3" \
      -activate net.kovidgoyal.kitty \
      -execute "HERDR_SOCKET_PATH='${HERDR_SOCKET_PATH:-}' '$herdr' agent focus '$3'" >/dev/null
  else
    notify-send "$1" "$2" 2>/dev/null || true
  fi
  # away from the Mac: also push to the phone through Collie
  idle=$(ioreg -c IOHIDSystem 2>/dev/null | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')
  collie=$(ls "$HOME"/.config/herdr/plugins/github/herdr.collie-*/bin/collie 2>/dev/null | head -1)
  if [ "${idle:-0}" -ge "$away_secs" ] && [ -n "$collie" ]; then
    if "$collie" push-test "$1" "$2" >/dev/null 2>&1; then toast "Also sent to phone" "$1: $2"; fi
  fi
}

case "$1" in
  reset)  # metadata tokens do not survive a server restart, so neither do markers
    rm -f "$dir"/* ;;
  once|sticky)  # same mode again turns it off; the other mode switches
    pane=${HERDR_PANE_ID:?no focused pane}
    cur=$(cat "$dir/$pane" 2>/dev/null || true); [ "$cur" = fired ] && cur=sticky
    if [ "$cur" = "$1" ]; then unmark "$pane"; toast "Watch off" "No more notifications for this pane"; exit 0; fi
    echo "$1" > "$dir/$pane"
    if [ "$1" = once ]; then mark "$pane" "👀"; toast "Watch on" "Notify once when this agent finishes"
    else mark "$pane" "📡"; toast "Watch on" "Notify every time this agent finishes"; fi ;;
  prompt)  # Claude Code hook: "ping me" / "notify me" in a prompt arms this pane once
    pane=${HERDR_PANE_ID:-}
    [ -n "$pane" ] && [ ! -e "$dir/$pane" ] || exit 0
    jq -r '.prompt // ""' | grep -qiE '(^|[^a-z])(ping|notify) me([^a-z]|$)' || exit 0
    echo once > "$dir/$pane"; mark "$pane" "👀"; toast "Watch on" "Notify once when this agent finishes" ;;
  tool)  # Claude Code PostToolUse hook: show pending wakeups and monitors in the sidebar
    pane=${HERDR_PANE_ID:-}; [ -n "$pane" ] || exit 0
    # ponytail: a Monitor that ends early keeps its token until its timeout; no hook fires on monitor exit
    args=$(jq -r '
      def hm: (./1000 | localtime | strftime("%H:%M"));
      if .tool_name == "ScheduleWakeup" then
        if .tool_response.stopped then "--clear-token\nwake"
        else (.tool_response.scheduledFor) as $t
          | "--token\nwake=\(if (.tool_input.reason // "" | startswith("cache-warm")) then "☕" else "⏰" end) \($t | hm)\n--ttl-ms\n\([$t - now*1000 + 60000, 1000] | max | floor)"
        end
      elif .tool_name == "Monitor" then
        (.tool_response.timeoutMs // 0) as $ms
        | "--token\nmon=👁 \(.tool_input.description // "monitor" | .[0:24])\n--ttl-ms\n\(if $ms > 0 then [$ms, 86400000] | min else 86400000 end)"
      elif .tool_name == "TaskStop" then "--clear-token\nmon"
      else empty end')
    [ -n "$args" ] || exit 0
    printf '%s\n' "$args" | tr '\n' '\0' | xargs -0 "$herdr" pane report-metadata "$pane" --source noah.watch.tool >/dev/null 2>&1 || true ;;
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
