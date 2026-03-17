#!/bin/bash

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

if [ "$CHARGING" != "" ]; then
  sketchybar --set $NAME icon.drawing=off label="bat ${PERCENTAGE}%+"
else
  sketchybar --set $NAME icon.drawing=off label="bat ${PERCENTAGE}%"
fi
