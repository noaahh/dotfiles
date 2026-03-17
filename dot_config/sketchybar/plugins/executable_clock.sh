#!/bin/bash

sketchybar --set $NAME label="$(date '+%a %d %b %H:%M:%S' | tr '[:upper:]' '[:lower:]')"
