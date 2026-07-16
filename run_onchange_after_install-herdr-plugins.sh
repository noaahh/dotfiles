#!/bin/sh

set -eu

if ! command -v herdr >/dev/null 2>&1; then
    exit 0
fi

herdr plugin install yankewei/herdr-focus-notify --yes
herdr plugin install thanhdat77/herdr-navigator --ref v0.3.2 --yes
herdr plugin install jwarykowski/shepherd --yes
herdr plugin install smarzban/herdr-file-viewer --yes
herdr plugin install persiyanov/herdr-reviewr --yes

if command -v jq >/dev/null 2>&1; then
    shepherd_root="$(herdr plugin list --json | jq -r '.result.plugins[] | select(.plugin_id == "jwarykowski.herdr-shepherd") | .plugin_root')"
    if [ -n "$shepherd_root" ]; then
        mkdir -p "$HOME/bin" "$HOME/.claude/skills"
        ln -sfn "$shepherd_root/bin/shepherd" "$HOME/bin/shepherd"
        ln -sfn "$shepherd_root/skills/shepherd" "$HOME/.claude/skills/shepherd"
    fi
fi

herdr server reload-config >/dev/null 2>&1 || true
