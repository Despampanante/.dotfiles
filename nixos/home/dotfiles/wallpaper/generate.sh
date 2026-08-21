#!/usr/bin/env bash
# Regenerates catppuccin-latte.png -- a plain Catppuccin Latte base/mantle
# gradient with two soft glows in the same accent colors used everywhere
# else (niri border, GTK theme, starship). Procedural rather
# than a downloaded image: no licensing to track, stays on-palette, and
# regenerates identically on any machine. Not wired into the Nix build --
# run by hand (needs imagemagick) whenever the source colors or target
# resolution change:
#   nix shell nixpkgs#imagemagick -c ./generate.sh
set -euo pipefail
cd "$(dirname "$0")"

magick -size 1920x1080 gradient:'#eff1f5-#e6e9ef' \
  \( -size 1920x1080 -define gradient:center=1920,1080 -define gradient:radius=1000 radial-gradient:'#fe640b40-#fe640b00' \) -compose over -composite \
  \( -size 1920x1080 -define gradient:center=0,0 -define gradient:radius=1000 radial-gradient:'#8839ef28-#8839ef00' \) -compose over -composite \
  catppuccin-latte.png
