#!/bin/bash
# Volume up/down/mute via pactl, reporting the new level to wob's overlay
# bar. Shared between sway and niri (both just call this on the XF86Audio*
# keys) instead of duplicating the pactl/wob plumbing per compositor.
set -euo pipefail

case "$1" in
  up)   pactl set-sink-volume @DEFAULT_SINK@ +5%;;
  down) pactl set-sink-volume @DEFAULT_SINK@ -5%;;
  mute) pactl set-sink-mute @DEFAULT_SINK@ toggle;;
esac

volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -m1 -oP '\d+(?=%)')

if pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes; then
  echo "$volume muted" > "$XDG_RUNTIME_DIR/wob.sock"
else
  echo "$volume" > "$XDG_RUNTIME_DIR/wob.sock"
fi
