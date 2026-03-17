#!/bin/bash

if [ "$1" = "$FOCUSED_WORKSPACE" ] || [ "$1" = "$(aerospace list-workspaces --focused)" ]; then
  sketchybar --set $NAME label.color=0xffffffff
else
  sketchybar --set $NAME label.color=0xff555555
fi
