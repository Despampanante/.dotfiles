#!/bin/bash
# Power menu — shared by both the sway and niri waybar configs. Uses
# fuzzel's dmenu mode in place of wofi. "Logout" is the one action that
# differs per compositor, so it's dispatched based on which IPC socket is
# present in the environment.

entries="Logout
Suspend
Reboot
Shutdown"

selected=$(printf '%s\n' "$entries" | fuzzel --dmenu --prompt="Power> " | tr '[:upper:]' '[:lower:]')

case $selected in
  logout)
    if [ -n "$SWAYSOCK" ]; then
      swaymsg exit
    elif [ -n "$NIRI_SOCKET" ]; then
      niri msg action quit
    fi
    ;;
  suspend)
    exec systemctl suspend;;
  reboot)
    exec systemctl reboot;;
  shutdown)
    exec systemctl poweroff -i;;
esac
