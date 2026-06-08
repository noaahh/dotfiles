#!/usr/bin/env bash

set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
HERDR_DIR="${HERDR_CONFIG_DIR:-$HOME/.config/herdr}"
SEARCH_LINES="${HERDR_SEARCH_LINES:-1000000}"
SEARCH_CACHE_DIR="${HERDR_SEARCH_CACHE_DIR:-$HERDR_DIR/search-cache}"
SEARCH_CACHE_TTL="${HERDR_SEARCH_CACHE_TTL:-0}"

mode="${1:-active}"
case "$mode" in
  active | --active) mode="active" ;;
  archived | archive | --archived | --archive) mode="archived" ;;
  *)
    printf 'usage: %s [active|archived]\n' "$0" >&2
    exit 2
    ;;
esac

tmpdir=$(mktemp -d)
trap 'loading_stop; rm -rf "$tmpdir"' EXIT

dim=$'\e[2m'
rst=$'\e[m'
green=$'\e[32m'
yellow=$'\e[33m'
red=$'\e[31m'
cyan=$'\e[36m'
magenta=$'\e[35m'
blue=$'\e[34m'

strip_control() {
  LC_ALL=C tr -cd '[:print:]\n\t'
}

trim_line() {
  LC_ALL=C sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//' | cut -c 1-220
}

fit_text() {
  local width="$1"
  local text="$2"
  if [[ "${#text}" -gt "$width" ]]; then
    printf '%s' "${text:0:$((width - 1))}…"
  else
    printf "%-${width}s" "$text"
  fi
}

flatten_field() {
  LC_ALL=C tr '\t\n' '  ' | trim_line
}

flatten_search() {
  LC_ALL=C tr '\t\n' '  ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

cache_is_fresh() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  local now mtime age
  now=$(date +%s)
  mtime=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || printf 0)
  [[ "$mtime" =~ ^[0-9]+$ ]] || mtime=0
  age=$((now - mtime))
  [[ "$age" -le "$SEARCH_CACHE_TTL" ]]
}

normalize_for_search() {
  perl -CS -pe '
    s/([A-Za-z0-9])s_/$1_/g;
    s/([A-Za-z0-9])s\b/$1/g;
  '
}

loading_start() {
  loading_message="$1"
  if [[ -t 2 ]]; then
    (
      frames='-\|/'
      i=0
      while :; do
        idx=$((i % ${#frames}))
        printf '\r%s %s' "$loading_message" "${frames:$idx:1}" >&2
        i=$((i + 1))
        sleep 0.12
      done
    ) &
    loading_pid=$!
  else
    printf '%s\n' "$loading_message" >&2
    loading_pid=""
  fi
}

loading_stop() {
  if [[ -n "${loading_pid:-}" ]]; then
    kill "$loading_pid" 2>/dev/null || true
    wait "$loading_pid" 2>/dev/null || true
    printf '\r\033[K' >&2
  fi
}

write_preview_helper() {
  cat > "$tmpdir/preview.sh" <<'PREVIEW'
#!/usr/bin/env bash
set -euo pipefail

file="$1"
query="${2:-}"
search_file="${3:-}"

highlight() {
  QUERY="$query" perl -CS -pe '
    BEGIN {
      %seen = ();
      for $raw (grep { length($_) > 1 } split /\s+/, ($ENV{QUERY} // "")) {
        @variants = ($raw);
        $singular = $raw;
        $singular =~ s/([A-Za-z0-9])s_/$1_/g;
        $singular =~ s/([A-Za-z0-9])s\b/$1/g;
        push @variants, $singular;
        $plural = $singular;
        $plural =~ s/([A-Za-z0-9])_/$1s_/g;
        push @variants, $plural;
        $plural_each = $singular;
        $plural_each =~ s/([A-Za-z0-9]+)(?=_|\b)/$1s/g;
        push @variants, $plural_each;
        for $term (@variants) {
          next if length($term) <= 1 || $seen{lc $term}++;
          push @raw_terms, $term;
        }
      }
      @terms = map { quotemeta($_) } sort { length($b) <=> length($a) } @raw_terms;
    }
    if (@terms) {
      $pattern = join "|", @terms;
      s/($pattern)/\e[30;43m$1\e[0m/ig;
    }
  '
}

if [[ -f "$file" ]]; then
  first_term=$(printf '%s' "$query" | awk '{ print $1 }')
  if [[ -n "$first_term" ]] && command -v rg >/dev/null 2>&1; then
    if rg -i -n -C 5 --color never -- "$first_term" "$file" 2>/dev/null \
      | sed -n '1,260p' \
      | highlight; then
      :
    elif [[ -f "$search_file" ]]; then
      normalized_term=$(printf '%s\n' "$first_term" | perl -CS -pe 's/([A-Za-z0-9])s_/$1_/g; s/([A-Za-z0-9])s\b/$1/g;')
      line=$(rg -i -n --color never -- "$normalized_term" "$search_file" 2>/dev/null | sed -n '1s/:.*//p')
      if [[ -n "$line" ]]; then
        start=$((line > 5 ? line - 5 : 1))
        end=$((line + 20))
        sed -n "${start},${end}p" "$file" | highlight
      fi
    fi
  else
    sed -n '1,260p' "$file" | highlight
  fi
fi
PREVIEW
  chmod +x "$tmpdir/preview.sh"
}

write_filter_helper() {
  cat > "$tmpdir/filter.sh" <<'FILTER'
#!/usr/bin/env bash
set -euo pipefail

entries="$1"
query="${2:-}"

tmp_query=$(mktemp)
trap 'rm -f "$tmp_query"' EXIT
printf '%s\n' "$query" \
  | perl -CS -pe '
      s/([A-Za-z0-9])s_/$1_/g;
      s/([A-Za-z0-9])s\b/$1/g;
    ' > "$tmp_query"

declare -A seen_ws
while IFS=$'\t' read -r display preview ws_id tab_id agent_pane search_file ws_prefix ws_blank child_display; do
  [[ -n "$display" ]] || continue
  matched=false
  if [[ -z "$query" ]]; then
    matched=true
  elif printf '%s\n' "$display" | rg -i -F -f "$tmp_query" >/dev/null 2>&1; then
    matched=true
  elif [[ -f "$search_file" ]] && rg -i -F -f "$tmp_query" "$search_file" >/dev/null 2>&1; then
    matched=true
  fi

  if [[ "$matched" == "true" ]]; then
    if [[ -n "${seen_ws[$ws_id]:-}" ]]; then
      display="${ws_blank}${child_display}"
    else
      display="${ws_prefix}${child_display}"
      seen_ws[$ws_id]=1
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$display" "$preview" "$ws_id" "$tab_id" "$agent_pane" "$search_file"
  fi
done < "$entries"
FILTER
  chmod +x "$tmpdir/filter.sh"
}

safe_name() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'
}

status_icon() {
  case "$1" in
    blocked) printf '%s!%s' "$red" "$rst" ;;
    working) printf '%s*%s' "$yellow" "$rst" ;;
    done) printf '%s✓%s' "$green" "$rst" ;;
    idle) printf '%so%s' "$green" "$rst" ;;
    *) printf '%s.%s' "$dim" "$rst" ;;
  esac
}

refresh_active_cache_sync() {
  loading_start "building active search index"
  "$HERDR_DIR/search-refresh.sh" active >/dev/null 2>&1 || true
  loading_stop
}

refresh_active_cache_background() {
  nohup "$HERDR_DIR/search-refresh.sh" active >/dev/null 2>&1 &
}

build_active_entries() {
  mkdir -p "$SEARCH_CACHE_DIR/active"
  mkdir -p "$SEARCH_CACHE_DIR/active-tabs"
  "$HERDR" workspace list > "$tmpdir/workspaces.json"
  "$HERDR" tab list > "$tmpdir/tabs.json"
  "$HERDR" pane list > "$tmpdir/panes.json"

  if ! compgen -G "$SEARCH_CACHE_DIR/active-tabs/*.search" >/dev/null; then
    refresh_active_cache_sync
    "$HERDR" workspace list > "$tmpdir/workspaces.json"
    "$HERDR" tab list > "$tmpdir/tabs.json"
    "$HERDR" pane list > "$tmpdir/panes.json"
  else
    refresh_active_cache_background
  fi

  : > "$tmpdir/entries"
  while IFS=$'\t' read -r ws_id ws_label ws_status focused; do
    icon=$(status_icon "$ws_status")
    [[ "$focused" == "true" ]] && marker="${cyan}>${rst}" || marker=" "
    tab_count=$(jq -r --arg ws "$ws_id" '[.result.tabs[] | select(.workspace_id == $ws)] | length' "$tmpdir/tabs.json")

    while IFS=$'\t' read -r tab_id tab_label tab_status tab_number; do
      tab_key=$(safe_name "$tab_id")
      preview="$SEARCH_CACHE_DIR/active-tabs/$tab_key.preview"
      search_file="$SEARCH_CACHE_DIR/active-tabs/$tab_key.search"
      agent_pane=""
      tab_cwd=""
      while IFS= read -r pane_id; do
        pane_cwd=$(jq -r --arg pane "$pane_id" '.result.panes[] | select(.pane_id == $pane) | .foreground_cwd // .cwd // ""' "$tmpdir/panes.json")
        pane_agent=$(jq -r --arg pane "$pane_id" '.result.panes[] | select(.pane_id == $pane) | .agent // ""' "$tmpdir/panes.json")
        [[ -z "$agent_pane" && -n "$pane_agent" ]] && agent_pane="$pane_id"
        [[ -z "$tab_cwd" && -n "$pane_cwd" ]] && tab_cwd="$pane_cwd"
      done < <(jq -r --arg tab "$tab_id" '.result.panes[] | select(.tab_id == $tab) | .pane_id' "$tmpdir/panes.json")
      [[ -f "$preview" ]] || printf 'indexing  %s / %s\n\nThis tab is being indexed in the background.\n' "$ws_label" "$tab_label" > "$preview"
      [[ -f "$search_file" ]] || printf '%s\n%s\n%s\n' "$ws_label" "$tab_label" "$tab_cwd" | normalize_for_search > "$search_file"
      row_icon=$(status_icon "$tab_status")
      ws_col=$(fit_text 18 "$ws_label")
      tab_col=$(fit_text 28 "$tab_label")
      ws_prefix="${marker} ${icon} ${ws_col} "
      ws_blank="    $(fit_text 18 "") "
      child_display="${row_icon} ${dim}${tab_number}${rst} ${tab_col} ${blue}${tab_cwd}${rst}"
      display="${ws_prefix}${child_display}"
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$display" "$preview" "$ws_id" "$tab_id" "$agent_pane" "$search_file" "$ws_prefix" "$ws_blank" "$child_display" >> "$tmpdir/entries"
    done < <(jq -r --arg ws "$ws_id" '.result.tabs[] | select(.workspace_id == $ws) | [.tab_id, (.label // "1"), (.agent_status // "unknown"), (.number|tostring)] | @tsv' "$tmpdir/tabs.json")
  done < <(jq -r '.result.workspaces[] | [.workspace_id, (.label // ""), (.agent_status // "unknown"), (.focused|tostring)] | @tsv' "$tmpdir/workspaces.json")
}

build_archived_entries() {
  history_file="$HERDR_DIR/session-history.json"
  session_file="$HERDR_DIR/session.json"
  : > "$tmpdir/entries"
  [[ -f "$history_file" ]] || return 0
  loading_start "indexing archived chats"

  jq -r '
    .workspaces as $history
    | ($history | length) as $workspace_count
    | range(0; $workspace_count) as $workspace_index
    | ($history[$workspace_index].tabs // []) as $tabs
    | range(0; ($tabs | length)) as $tab_index
    | (($tabs[$tab_index].panes // {}) | to_entries[]) as $pane
    | [
        $workspace_index,
        $tab_index,
        $pane.key,
        ($pane.value.lines // 0),
        (($pane.value.ansi // "") | @base64)
      ]
    | @tsv
  ' "$history_file" | while IFS=$'\t' read -r workspace_index tab_index pane_key lines ansi_b64; do
    workspace_cwd=$(jq -r --argjson index "$workspace_index" '.workspaces[$index].identity_cwd // ""' "$session_file" 2>/dev/null || true)
    workspace_name=$(jq -r --argjson index "$workspace_index" '.workspaces[$index].custom_name // .workspaces[$index].identity_cwd // ("workspace " + ($index + 1 | tostring))' "$session_file" 2>/dev/null || true)
    tab_name=$(jq -r --argjson workspace "$workspace_index" --argjson tab "$tab_index" '.workspaces[$workspace].tabs[$tab].custom_name // ("tab " + ($tab + 1 | tostring))' "$session_file" 2>/dev/null || true)
    [[ -z "$workspace_name" || "$workspace_name" == "null" ]] && workspace_name="workspace $((workspace_index + 1))"
    [[ -z "$tab_name" || "$tab_name" == "null" ]] && tab_name="tab $((tab_index + 1))"

    key="w${workspace_index}_t${tab_index}_p${pane_key}"
    text_file="$tmpdir/text_$key"
    preview="$tmpdir/preview_$key"

    printf '%s' "$ansi_b64" \
      | base64 --decode \
      | perl -CS -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g; s/\r/\n/g' \
      | strip_control > "$text_file"

    {
      printf 'archived  %s / %s  pane %s  %s lines\n\n' "$workspace_name" "$tab_name" "$pane_key" "$lines"
      sed -n '1,260p' "$text_file"
    } > "$preview"

    title=$(grep -v '^[[:space:]]*$' "$text_file" | tail -n 1 | trim_line || true)
    [[ -z "$title" ]] && title="$workspace_name / $tab_name"
    search_text=$(tr '\n' ' ' < "$text_file" 2>/dev/null || true)
    if [[ -n "$workspace_cwd" && "$workspace_cwd" != "null" ]]; then
      cwd_label=" ${blue}${workspace_cwd}${rst}"
    else
      cwd_label=""
    fi
    ws_col=$(fit_text 18 "$workspace_name")
    tab_col=$(fit_text 28 "$tab_name")
    ws_prefix="  ${magenta}archived${rst} ${ws_col} "
    ws_blank="           $(fit_text 18 "") "
    child_display="${tab_col} ${dim}pane ${pane_key}${rst}${cwd_label} ${title}"
    display="${ws_prefix}${child_display}"
    search_file="$tmpdir/search_$key"
    printf '%s\n%s\n' "$display" "$search_text" | normalize_for_search > "$search_file"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$display" "$preview" "archive-$workspace_index" "" "" "$search_file" "$ws_prefix" "$ws_blank" "$child_display" >> "$tmpdir/entries"
  done
  loading_stop
}

run_fzf() {
  local header prompt selected
  if [[ "$mode" == "active" ]]; then
    header='active Herdr chats: enter focuses selection'
    if [[ "$(cat "$SEARCH_CACHE_DIR/status" 2>/dev/null || true)" == "refreshing" ]]; then
      header='active Herdr chats: enter focuses selection | refreshing index in background'
    fi
    prompt='active> '
  else
    header='archived Herdr pane history: all integrated agents'
    prompt='archive> '
  fi

  write_preview_helper
  write_filter_helper
  "$tmpdir/filter.sh" "$tmpdir/entries" "" > "$tmpdir/visible_entries"
  selected=$(fzf \
    --ansi \
    --no-sort \
    --disabled \
    --layout reverse \
    --delimiter $'\t' \
    --with-nth 1 \
    --highlight-line \
    --prompt "$prompt" \
    --info inline \
    --header "$header" \
    --bind "change:reload:$tmpdir/filter.sh $tmpdir/entries {q}" \
    --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
    --preview "$tmpdir/preview.sh {2} {q} {6}" \
    --preview-window 'down:60%:wrap' \
    < "$tmpdir/visible_entries") || true

  [[ -n "$selected" ]] || return 1
  selected=$(printf '%s\n' "$selected" | sed -n '1p')
  printf '%s' "$selected"
}

focus_selection() {
  local ws_id="$1"
  local tab_id="$2"
  local agent_pane="$3"

  "$HERDR" workspace focus "$ws_id" >/dev/null
  [[ -n "$tab_id" ]] && "$HERDR" tab focus "$tab_id" >/dev/null
  [[ -n "$agent_pane" ]] && "$HERDR" agent focus "$agent_pane" >/dev/null
}

refocus_after_command_pane_closes() {
  local ws_id="$1"
  local tab_id="$2"
  local agent_pane="$3"

  nohup bash -c '
    set +e
    herdr_bin="$1"
    ws_id="$2"
    tab_id="$3"
    agent_pane="$4"

    sleep 0.12
    for _ in 1 2 3 4 5 6; do
      "$herdr_bin" workspace focus "$ws_id" >/dev/null 2>&1
      [[ -n "$tab_id" ]] && "$herdr_bin" tab focus "$tab_id" >/dev/null 2>&1
      [[ -n "$agent_pane" ]] && "$herdr_bin" agent focus "$agent_pane" >/dev/null 2>&1
      sleep 0.08
    done
  ' _ "$HERDR" "$ws_id" "$tab_id" "$agent_pane" >/dev/null 2>&1 &
}

if [[ "$mode" == "active" ]]; then
  build_active_entries
else
  build_archived_entries
fi

if [[ ! -s "$tmpdir/entries" ]]; then
  printf 'no %s chats found\n' "$mode" >&2
  exit 0
fi

selected=$(run_fzf) || exit 0
[[ -n "$selected" ]] || exit 0

if [[ "$mode" == "active" ]]; then
  ws_id=$(printf '%s' "$selected" | cut -f3)
  tab_id=$(printf '%s' "$selected" | cut -f4)
  agent_pane=$(printf '%s' "$selected" | cut -f5)
  focus_selection "$ws_id" "$tab_id" "$agent_pane"
  refocus_after_command_pane_closes "$ws_id" "$tab_id" "$agent_pane"
else
  preview_file=$(printf '%s' "$selected" | cut -f2)
  sed -n '1,2p' "$preview_file"
fi
