#!/usr/bin/env bash
# Fuzzy window switcher for niri: lists open windows through fuzzel (same
# tool as the app launcher, just fed real data instead of the app list) and
# focuses whichever one is picked. `focus-window` also switches to that
# window's workspace on its own -- confirmed live, no extra plumbing needed
# for that part.
#
# Real per-app icons, same as the launcher shows -- fuzzel's --dmenu mode
# supports Rofi's extended dmenu protocol (append \0icon\x1f<name> to a
# line), confirmed via `man fuzzel`. Uses the window's own app-id directly
# as the icon name rather than a hardcoded per-app mapping -- most icon
# themes name their icon after the same string used as the desktop/app id
# (confirmed for ghostty/chrome/discord/steam), and fuzzel just silently
# shows no icon if a name doesn't resolve, so this doesn't need to be more
# elaborate than that. Not --dmenu0 -- the man page says icons aren't
# supported in that mode.
#
# fuzzel --index (not embedding the window id in the visible text) keeps
# the display clean -- it prints the selected line's position instead of
# its text, looked up against a parallel array of real window ids below.
set -euo pipefail

json=$(niri msg -j windows)

mapfile -t ids < <(jq -r '.[].id' <<< "$json")

index=$(
  jq -r '.[] | .title + "  —  " + .app_id + "\u0000icon\u001f" + .app_id' <<< "$json" \
    | fuzzel --dmenu --index --prompt "❯ "
)

niri msg action focus-window --id "${ids[$index]}"
