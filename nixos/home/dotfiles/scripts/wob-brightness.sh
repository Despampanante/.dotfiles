#!/bin/bash
# Backlight up/down via brightnessctl, reporting the new level to wob's
# overlay bar. Shared between sway and niri.
set -euo pipefail

case "$1" in
  up)   brightnessctl -c backlight set +5% -q;;
  down) brightnessctl -c backlight set 5%- -q;;
esac

percent=$(brightnessctl -c backlight get -m | cut -d, -f4 | tr -d '%')
echo "$percent" > "$XDG_RUNTIME_DIR/wob.sock"
