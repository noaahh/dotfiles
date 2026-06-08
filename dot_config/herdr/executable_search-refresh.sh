#!/usr/bin/env bash

set -euo pipefail

HERDR="${HERDR_BIN_PATH:-herdr}"
HERDR_DIR="${HERDR_CONFIG_DIR:-$HOME/.config/herdr}"
SEARCH_LINES="${HERDR_SEARCH_LINES:-1000000}"
SEARCH_CACHE_DIR="${HERDR_SEARCH_CACHE_DIR:-$HERDR_DIR/search-cache}"
SEARCH_CACHE_TTL="${HERDR_SEARCH_CACHE_TTL:-0}"

active_dir="$SEARCH_CACHE_DIR/active"
tab_dir="$SEARCH_CACHE_DIR/active-tabs"
mkdir -p "$active_dir" "$tab_dir"

safe_name() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'
}

strip_control() {
  LC_ALL=C tr -cd '[:print:]\n\t'
}

normalize_for_search() {
  perl -CS -pe '
    s/([A-Za-z0-9])s_/$1_/g;
    s/([A-Za-z0-9])s\b/$1/g;
  '
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

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

"$HERDR" workspace list > "$tmpdir/workspaces.json"
"$HERDR" tab list > "$tmpdir/tabs.json"
"$HERDR" pane list > "$tmpdir/panes.json"

printf 'refreshing\n' > "$SEARCH_CACHE_DIR/status"

while IFS= read -r pane_id; do
  pane_key=$(safe_name "$pane_id")
  pane_cache="$active_dir/$pane_key.txt"
  pane_search="$active_dir/$pane_key.search"
  if cache_is_fresh "$pane_cache" && cache_is_fresh "$pane_search"; then
    continue
  fi
  raw_tmp="$tmpdir/$pane_key.txt"
  search_tmp="$tmpdir/$pane_key.search"
  "$HERDR" pane read "$pane_id" --source recent-unwrapped --lines "$SEARCH_LINES" --format text 2>/dev/null \
    | strip_control > "$raw_tmp" || : > "$raw_tmp"
  normalize_for_search < "$raw_tmp" > "$search_tmp"
  mv "$raw_tmp" "$pane_cache"
  mv "$search_tmp" "$pane_search"
done < <(jq -r '.result.panes[].pane_id' "$tmpdir/panes.json")

while IFS=$'\t' read -r tab_id tab_label ws_id; do
  tab_key=$(safe_name "$tab_id")
  preview_tmp="$tmpdir/$tab_key.preview"
  search_tmp="$tmpdir/$tab_key.search"
  preview_cache="$tab_dir/$tab_key.preview"
  search_cache="$tab_dir/$tab_key.search"
  ws_label=$(jq -r --arg ws "$ws_id" '.result.workspaces[] | select(.workspace_id == $ws) | .label // ""' "$tmpdir/workspaces.json")

  : > "$search_tmp"
  {
    printf 'active  %s / %s\n\n' "$ws_label" "$tab_label"
    while IFS= read -r pane_id; do
      pane_key=$(safe_name "$pane_id")
      pane_file="$active_dir/$pane_key.txt"
      pane_search="$active_dir/$pane_key.search"
      pane_cwd=$(jq -r --arg pane "$pane_id" '.result.panes[] | select(.pane_id == $pane) | .foreground_cwd // .cwd // ""' "$tmpdir/panes.json")
      printf '%s\n' "$pane_cwd"
      sed -n "1,${SEARCH_LINES}p" "$pane_file" 2>/dev/null || true
      printf '\n\n'
      printf '%s\n' "$pane_cwd" >> "$search_tmp"
      cat "$pane_search" >> "$search_tmp" 2>/dev/null || true
    done < <(jq -r --arg tab "$tab_id" '.result.panes[] | select(.tab_id == $tab) | .pane_id' "$tmpdir/panes.json")
  } > "$preview_tmp"

  normalize_for_search < "$search_tmp" > "$search_tmp.normalized"
  mv "$search_tmp.normalized" "$search_tmp"
  mv "$preview_tmp" "$preview_cache"
  mv "$search_tmp" "$search_cache"
done < <(jq -r '.result.tabs[] | [.tab_id, (.label // "1"), .workspace_id] | @tsv' "$tmpdir/tabs.json")

date +%s > "$SEARCH_CACHE_DIR/indexed_at"
printf 'ready\n' > "$SEARCH_CACHE_DIR/status"
