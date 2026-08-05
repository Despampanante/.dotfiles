# wlogout replaces the old fuzzel-dmenu power-menu.sh script (see
# DECISIONS.md) -- a proper themed power menu instead of a plain text list.
# `loginctl terminate-user $USER` for logout is compositor-agnostic (unlike
# the old script's swaymsg-vs-niri-msg branching), since it goes through
# systemd-logind rather than either compositor's own IPC.
{ pkgs, ... }:

{
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "swaylock -f -C ~/.config/swaylock/config";
        text = "Lock";
        keybind = "l";
        circular = true;
      }
      {
        label = "logout";
        action = "loginctl terminate-user $USER";
        text = "Logout";
        keybind = "e";
        circular = true;
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
        circular = true;
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
        circular = true;
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
        circular = true;
      }
    ];

    # Catppuccin Latte, hand-applied (no catppuccin.nix module for wlogout,
    # same situation as swaync/sway/niri -- see DECISIONS.md). Icon paths
    # point at nixpkgs' own bundled wlogout icons via ${pkgs.wlogout}, same
    # ones its default /etc/wlogout/style.css references.
    style = ''
      * {
        background-image: none;
        box-shadow: none;
        font-family: "Iosevka Nerd Font";
      }

      window {
        background-color: rgba(239, 241, 245, 0.85); /* base, translucent */
      }

      button {
        border-radius: 100px;
        border: 2px solid #acb0be; /* surface2 */
        background-color: #ccd0da; /* surface0 */
        background-repeat: no-repeat;
        background-position: center;
        background-size: 35%;
        margin: 12px;
      }

      button:focus,
      button:active,
      button:hover {
        background-color: #fe640b; /* peach */
        border-color: #fe640b;
        outline-style: none;
      }

      #lock {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
      }
      #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
      }
      #suspend {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      }
      #reboot {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
      }
      #shutdown {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
      }
    '';
  };
}
