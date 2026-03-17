#!/bin/bash

CPU=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
sketchybar --set $NAME icon.drawing=off label="cpu ${CPU}%"
