#!/bin/bash

sketchybar --set $NAME label="$(date '+%d %b %H:%M:%S' | tr '[:upper:]' '[:lower:]')"
