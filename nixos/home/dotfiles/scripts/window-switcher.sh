#!/usr/bin/env bash
# Fuzzy window switcher for niri: lists open windows through fuzzel (same
# tool as the app launcher, just fed real data instead of the app list) and
# focuses whichever one is picked. `focus-window` also switches to that
# window's workspace on its own -- confirmed live, no extra plumbing needed
# for that part.
#
# The window id is embedded at the end of each displayed line (fuzzel's
# dmenu mode only ever returns the exact line text, no separate metadata
# channel) and stripped back out of the selection afterwards.
set -euo pipefail

selection=$(
  niri msg -j windows \
    | jq -r '.[] | "\(.title)  —  \(.app_id)  [\(.id)]"' \
    | fuzzel --dmenu --prompt "window> "
)

id=$(grep -oP '(?<=\[)\d+(?=\]$)' <<< "$selection")

niri msg action focus-window --id "$id"
