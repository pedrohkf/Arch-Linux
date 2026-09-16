#!/usr/bin/env bash
# Menu visual (wofi) pra escolher o tema ativo.
set -euo pipefail

THEMES_DIR="$HOME/.config/hypr/themes"
SWITCH="$HOME/.config/hypr/theme-manager/theme-switch.sh"
current="$(cat "$HOME/.config/hypr/current-theme" 2>/dev/null || echo '?')"

choice=$(find "$THEMES_DIR" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort | \
    awk -v cur="$current" '{ mark = ($0 == cur) ? " (atual)" : ""; print $0 mark }' | \
    wofi --dmenu -p "Tema")

[ -z "$choice" ] && exit 0

theme_id="${choice%% (atual)}"
theme_id="${theme_id%%-*}"

"$SWITCH" "$theme_id"
