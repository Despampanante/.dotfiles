#!/usr/bin/env bash
# Fuzzy window switcher for niri: lists open windows through fuzzel (same
# tool as the app launcher, just fed real data instead of the app list) and
# focuses whichever one is picked. `focus-window` also switches to that
# window's workspace on its own -- confirmed live, no extra plumbing needed
# for that part.
#
# Per-app icons -- codepoints confirmed present in the installed Iosevka
# Nerd Font via fontTools before use (this font build is missing some
# glyphs a full Nerd Font install would have, see DECISIONS.md's waybar
# icon entries -- checking first avoided repeating that bug here).
#
# fuzzel --index (not embedding the window id in the visible text) keeps
# the display clean -- it prints the selected line's position instead of
# its text, looked up against a parallel array of real window ids below.
set -euo pipefail

json=$(niri msg -j windows)

mapfile -t ids < <(jq -r '.[].id' <<< "$json")

index=$(
  jq -r '
    .[] |
    (
      if .app_id == "org.wezfurlong.wezterm" then ""
      elif .app_id == "google-chrome" then ""
      elif .app_id == "discord" then ""
      elif .app_id == "Spotify" then ""
      elif .app_id == "md.Obsidian" then ""
      else ""
      end
    ) + "  " + .title + "  —  " + .app_id
  ' <<< "$json" \
    | fuzzel --dmenu --index --prompt "window> "
)

niri msg action focus-window --id "${ids[$index]}"
