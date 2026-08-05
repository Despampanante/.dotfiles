#!/usr/bin/env bash
# Volume up/down/mute via wpctl (PipeWire's native control CLI), reporting
# the new level to wob's overlay bar. Shared between sway and niri (both
# just call this on the XF86Audio* keys) instead of duplicating the
# wpctl/wob plumbing per compositor.
#
# Not pactl: this system runs PipeWire directly (services.pulseaudio.enable
# = false), and pactl (the pulseaudio-utils CLI) was never actually
# installed -- wpctl is PipeWire/WirePlumber's own equivalent and is
# already on PATH.
set -euo pipefail

case "$1" in
  up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+;;
  down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-;;
  mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle;;
esac

# `wpctl get-volume` prints e.g. "Volume: 0.45" or "Volume: 0.45 [MUTED]" --
# no percent sign, so scale and round rather than pattern-match a "%".
status=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
volume=$(grep -oP '(?<=Volume: )[0-9.]+' <<< "$status" | awk '{printf "%.0f", $1 * 100}')

if [[ "$status" == *MUTED* ]]; then
  echo "$volume muted" > "$XDG_RUNTIME_DIR/wob.sock"
else
  echo "$volume" > "$XDG_RUNTIME_DIR/wob.sock"
fi
