#!/bin/bash

INTERFACE=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')
if [ -z "$INTERFACE" ]; then
  sketchybar --set $NAME icon.drawing=off label="net ↓  0.0K ↑  0.0K"
  exit 0
fi

read IN_PREV OUT_PREV < /tmp/sketchybar_net_prev 2>/dev/null || { IN_PREV=0; OUT_PREV=0; }

STATS=$(netstat -I "$INTERFACE" -b | tail -1 | awk '{print $7, $10}')
IN_NOW=$(echo "$STATS" | awk '{print $1}')
OUT_NOW=$(echo "$STATS" | awk '{print $2}')

IN_DIFF=$(( IN_NOW - IN_PREV ))
OUT_DIFF=$(( OUT_NOW - OUT_PREV ))

[ "$IN_DIFF" -lt 0 ] && IN_DIFF=0
[ "$OUT_DIFF" -lt 0 ] && OUT_DIFF=0

echo "$IN_NOW $OUT_NOW" > /tmp/sketchybar_net_prev

format_speed() {
  local bytes=$1
  if [ "$bytes" -ge 1048576 ]; then
    printf "%5.1fM" "$(echo "scale=1; $bytes / 1048576" | bc)"
  else
    printf "%5.1fK" "$(echo "scale=1; $bytes / 1024" | bc)"
  fi
}

IN_FMT=$(format_speed $IN_DIFF)
OUT_FMT=$(format_speed $OUT_DIFF)

sketchybar --set $NAME icon.drawing=off label="net ↓${IN_FMT} ↑${OUT_FMT}"
