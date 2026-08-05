#!/usr/bin/env bash
# Backlight up/down via brightnessctl, reporting the new level to wob's
# overlay bar. Shared between sway and niri.
set -euo pipefail

case "$1" in
  up)   brightnessctl -c backlight set +5% -q;;
  down) brightnessctl -c backlight set 5%- -q;;
esac

# `-m` (machine-readable) only has an effect on the default `info` action --
# `get` ignores it and always prints the bare current value (e.g. "65535",
# not a percent), so this has to omit `get` rather than combine the two.
percent=$(brightnessctl -c backlight -m | cut -d, -f4 | tr -d '%')
echo "$percent" > "$XDG_RUNTIME_DIR/wob.sock"
