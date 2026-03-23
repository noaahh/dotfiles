#!/bin/bash

if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set $NAME label="$(echo "$INFO" | tr '[:upper:]' '[:lower:]')" \
                         icon="$($CONFIG_DIR/plugins/icon_map.sh "$INFO")"
fi
