#!/bin/bash

CONFIG="$HOME/.config/aerospace/aerospace.toml"

MONITORS=$(aerospace list-monitors --json 2>/dev/null)
MONITOR_COUNT=$(echo "$MONITORS" | grep -c '"monitor-name"')
HAS_BUILTIN=$(echo "$MONITORS" | grep -ci "built-in")

if [ "$MONITOR_COUNT" -eq 1 ] && [ "$HAS_BUILTIN" -gt 0 ]; then
  sed -i '' 's/outer.top = [0-9]*/outer.top = 0/' "$CONFIG"
else
  sed -i '' 's/outer.top = [0-9]*/outer.top = 24/' "$CONFIG"
fi

aerospace reload-config
