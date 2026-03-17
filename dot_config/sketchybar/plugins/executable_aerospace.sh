#!/bin/bash

# Highlight the active aerospace workspace
if [ "$1" = "$FOCUSED_WORKSPACE" ] || [ "$1" = "$(aerospace list-workspaces --focused)" ]; then
  sketchybar --set $NAME background.color=0xff7aa2f7 \
                         icon.color=0xff1e1e2e
else
  sketchybar --set $NAME background.color=0x00000000 \
                         icon.color=0xffcad3f5
fi
