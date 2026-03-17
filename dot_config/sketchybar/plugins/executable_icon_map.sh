#!/bin/bash

# Map app names to sketchybar-app-font icons
# See: https://github.com/kvndrsslr/sketchybar-app-font
case "$1" in
  "kitty"|"Terminal"|"iTerm2"|"Alacritty"|"WezTerm") echo ":terminal:" ;;
  "Safari") echo ":safari:" ;;
  "Firefox") echo ":firefox:" ;;
  "Google Chrome") echo ":google_chrome:" ;;
  "Arc") echo ":arc:" ;;
  "Code"|"Visual Studio Code") echo ":visual_studio_code:" ;;
  "Finder") echo ":finder:" ;;
  "Slack") echo ":slack:" ;;
  "Microsoft Teams"*) echo ":microsoft_teams:" ;;
  "Microsoft Outlook") echo ":microsoft_outlook:" ;;
  "Messages") echo ":messages:" ;;
  "Mail") echo ":mail:" ;;
  "Notes") echo ":notes:" ;;
  "Obsidian") echo ":obsidian:" ;;
  "System Preferences"|"System Settings") echo ":gear:" ;;
  "Spotify") echo ":spotify:" ;;
  "Music") echo ":music:" ;;
  "Discord") echo ":discord:" ;;
  "Preview") echo ":preview:" ;;
  "Fork") echo ":fork:" ;;
  "Linear") echo ":linear:" ;;
  "Helium") echo ":helium:" ;;
  *) echo ":default:" ;;
esac
