# Waybar, Nix-native (see DECISIONS.md — "Rewired waybar/fuzzel/swaylock
# through catppuccin/nix" for why this moved off plain xdg.configFile).
# Sway's bar is the "real" home-manager module (programs.waybar), which is
# what lets catppuccin.waybar actually hook in and gives us free
# reload-on-rebuild (home-manager SIGUSR2's waybar automatically when
# settings/style change). Niri needs a second, differently-named config file
# (config-niri) since it spawns waybar explicitly rather than using a native
# `bar {}` block like sway — programs.waybar only ever manages one
# `waybar/config`, so that one's still hand-generated JSON, just from the
# same shared Nix attrset instead of a hand-duplicated file.
{ pkgs, ... }:

let
  shared = {
    layer = "top";
    position = "top";
    height = 26;
    "margin-top" = 6;
    "margin-left" = 6;
    "margin-right" = 6;

    "modules-right" = [ "group/status" "group/system" ];

    "group/status" = {
      orientation = "horizontal";
      modules = [ "pulseaudio" "battery" "backlight#icon" "backlight#value" ];
    };
    "group/system" = {
      orientation = "horizontal";
      modules = [ "custom/notification" "clock" "tray" "custom/power" ];
    };

    battery = {
      states = {
        warning = 30;
        critical = 15;
      };
      format = "{capacity}% {icon}";
      "format-charging" = "{capacity}% ";
      "format-plugged" = "{capacity}% ";
      "format-icons" = [ "" "" "" "" "" ];
    };

    clock = {
      interval = 10;
      "format-alt" = " {:%e %b %Y}";
      format = "{:%H:%M}";
      "tooltip-format" = "{:%e %B %Y}";
    };

    pulseaudio = {
      "scroll-step" = 1;
      format = "{volume}% {icon}";
      "format-bluetooth" = "{volume}% {icon}  {format_source}";
      "format-bluetooth-muted" = " {icon}  {format_source}";
      "format-muted" = "婢 {format_source}";
      "format-source" = "{volume}% ";
      "format-source-muted" = "";
      "format-icons" = {
        headphone = "";
        "hands-free" = "וֹ";
        headset = "  ";
        phone = "";
        portable = "";
        car = "";
        default = [ "" ];
      };
      "on-click" = "pavucontrol";
      "on-scroll-up" = "pactl set-sink-volume @DEFAULT_SINK@ +2%";
      "on-scroll-down" = "pactl set-sink-volume @DEFAULT_SINK@ -2%";
    };

    tray = {
      "icon-size" = 18;
      spacing = 10;
    };

    "backlight#icon" = {
      format = "{icon}";
      "format-icons" = [ "" ];
      "on-scroll-down" = "brightnessctl -c backlight set 1%-";
      "on-scroll-up" = "brightnessctl -c backlight set +1%";
    };
    "backlight#value" = {
      format = "{percent}%";
      "on-scroll-down" = "brightnessctl -c backlight set 1%-";
      "on-scroll-up" = "brightnessctl -c backlight set +1%";
    };

    "custom/launcher" = {
      format = " ";
      "on-click" = "exec fuzzel";
      tooltip = false;
    };

    "custom/notification" = {
      tooltip = false;
      format = "{icon}";
      "format-icons" = {
        notification = "<span foreground='#6d0022'></span>";
        none = "";
        "dnd-notification" = "<span foreground='#6d0022'></span>";
        "dnd-none" = "";
        "inhibited-notification" = "<span foreground='#6d0022'></span>";
        "inhibited-none" = "";
        "dnd-inhibited-notification" = "<span foreground='#6d0022'></span>";
        "dnd-inhibited-none" = "";
      };
      "return-type" = "json";
      "exec-if" = "which swaync-client";
      exec = "swaync-client -swb";
      "on-click" = "swaync-client -t -sw";
      "on-click-right" = "swaync-client -d -sw";
      escape = true;
    };

    "custom/power" = {
      format = "⏻";
      "on-click" = "exec wlogout -b 5"; # one row, no empty grid cell for 5 buttons
      tooltip = false;
    };
  };

  swayBar = shared // {
    "modules-left" = [ "sway/workspaces" "sway/mode" ];
    "modules-center" = [ "sway/window" ];

    "sway/mode" = {
      format = "{}";
      tooltip = false;
    };
    "sway/window" = {
      format = "{}";
      "max-length" = 60;
    };
    "sway/workspaces" = {
      "disable-scroll" = true;
      "disable-markup" = false;
      "all-outputs" = true;
      format = "  {icon}  ";
      "format-icons" = {
        "1" = "";
        "2" = "";
        "3" = "";
        "4" = "";
      };
    };
  };

  niriBar = shared // {
    "modules-left" = [ "niri/workspaces" ];
    "modules-center" = [ "niri/window" ];

    "niri/window" = {
      format = "{}";
      "max-length" = 60;
    };
    "niri/workspaces" = {
      format = "  {icon}  ";
      "format-icons" = {
        "1" = "";
        "2" = "";
        "3" = "";
        "4" = "";
      };
    };
  };

  jsonFormat = pkgs.formats.json { };
in
{
  programs.waybar = {
    enable = true;
    settings = [ swayBar ];
    style = builtins.readFile ./dotfiles/waybar/style.css;
  };

  xdg.configFile."waybar/config-niri".source = jsonFormat.generate "waybar-config-niri.json" niriBar;

  catppuccin.waybar = {
    enable = true;
    mode = "prependImport";
  };
}
