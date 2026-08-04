#!/bin/bash
# Screenshot picker — sway-only (niri has its own built-in screenshot UI,
# bound directly in niri's config instead). Uses fuzzel's dmenu mode in
# place of wofi, and grimshot (from nixpkgs' sway-contrib.grimshot, already
# on PATH) instead of the hardcoded /usr/share/sway/scripts/grimshot path
# the legacy dotfiles used.

entries="Active
Screen
Area
Window"

selected=$(printf '%s\n' "$entries" | fuzzel --dmenu --prompt="Screenshot> " | tr '[:upper:]' '[:lower:]')

case $selected in
  active)
    grimshot --notify save active;;
  screen)
    grimshot --notify save screen;;
  area)
    grimshot --notify save area;;
  window)
    grimshot --notify save window;;
esac
