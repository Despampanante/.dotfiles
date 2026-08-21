# Host-specific home-manager config: this laptop's actual desktop (niri,
# DankMaterialShell, GPU offload wrappers, browser/Discord/etc). The
# portable shell/git/editor/dev-CLI subset lives in ./core.nix, imported
# below -- see that file for why the split, and for what's usable standalone
# (via `homeConfigurations.santi` in flake.nix) on another machine.
#
# Config files under ./dotfiles referenced here (and, where noted in
# DECISIONS.md, recolored) are pulled from
# https://github.com/Despampanante/.dotfiles — deliberately kept as plain
# dotfiles rather than rewritten into home-manager's structured options, so
# they stay usable as-is on Windows too (via chezmoi, per that repo's setup).

{ config, pkgs, inputs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};

  # A small stable-named wrapper for the polkit authentication agent --
  # niri/config.kdl spawns it at startup (see that file), but the real
  # binary lives under a /nix/store/<hash>-polkit-gnome-.../libexec path
  # that changes every build/generation, so a plain dotfile can't reference
  # it directly (confirmed: the old hardcoded /usr/lib/polkit-gnome/... path
  # never existed on NixOS at all -- the agent was silently never running).
  # This wrapper gives it a fixed PATH-resolvable name instead, so niri's
  # plain-dotfile spawn command keeps working unchanged.
  polkitAgentWrapper = pkgs.writeShellScriptBin "polkit-agent-wrapper"
    "exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";

  # Wrapper so nirinit's restore of the terminal (configuration.nix's
  # services.nirinit.settings.launch) lands inside tmux instead of a bare
  # shell. nirinit can only ever pass a single bare executable name with no
  # arguments -- confirmed by reading its source (`vec![launch_command]`,
  # always one Vec element) and niri's own spawn() (execs Vec elements
  # directly, no shell involved, so a launch string with embedded flags
  # would just fail to exec as one literal nonexistent binary name). Same
  # fixed-name-wrapper pattern as polkitAgentWrapper above, just for a
  # multi-arg command instead of an unstable store path.
  ghosttyTmuxAttach = pkgs.writeShellScriptBin "ghostty-tmux-attach"
    "exec ${pkgs.ghostty}/bin/ghostty -e ${pkgs.bash}/bin/sh -c 'tmux attach || tmux new'";

  # Sticky floating windows for niri -- see niri/config.kdl for the
  # spawn-at-startup + Mod+G toggle bind. Plain flake package, not a
  # nixpkgs one.
  niriFloatSticky = inputs.niri-float-sticky.packages.${pkgs.stdenv.system}.default;

  # Catppuccin's official DankMaterialShell theme -- bundles all four
  # flavors (Latte/Frappé/Macchiato/Mocha) in one catppuccin.json, picked
  # inside DMS itself (see xdg.configFile below for where it's placed).
  # Fetched declaratively rather than the upstream "download the file by
  # hand" instructions, same reasoning as tpm in core.nix.
  catppuccinDMSTheme = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "dankmaterialshell";
    rev = "c99287f89c51dcb5623772d07512f4d49f696994";
    hash = "sha256-LCMpazzd1BG4CyucduvDBGtP/Rhi5PKsg755PPEusz0=";
  };

  # Blender wrapped through `nvidia-offload` (the command legion-laptop's
  # `hardware.nvidia.prime.offload.enableOffloadCmd` puts on PATH -- see
  # configuration.nix): this hybrid-graphics laptop otherwise runs GUI apps
  # on the AMD iGPU by default, which leaves Cycles GPU rendering
  # (CUDA/OptiX) unused on the RTX dGPU. Calls the real binary by store
  # path rather than by name off PATH, so this wrapper doesn't need plain
  # `blender` installed alongside it too. Ships its own
  # `share/applications` + `share/icons` (copied straight from the real
  # blender package, not hand-rolled) so it shows up in fuzzel as a normal
  # "Blender" launcher rather than a bare `blender` binary with no icon.
  blenderOffload =
    let
      wrapped = pkgs.writeShellScriptBin "blender" ''
        exec nvidia-offload "${pkgs.blender}/bin/blender" "$@"
      '';
      desktop = pkgs.makeDesktopItem {
        name = "blender";
        desktopName = "Blender";
        comment = "3D creation suite (NVIDIA dGPU offload)";
        exec = "blender %f";
        icon = "blender";
        terminal = false;
        categories = [ "Graphics" ];
      };
      icons = pkgs.runCommand "blender-icons" { } ''
        mkdir -p $out/share
        cp -r ${pkgs.blender}/share/icons $out/share/icons
      '';
    in
    pkgs.symlinkJoin {
      name = "blender-offload";
      paths = [ wrapped desktop icons ];
    };
in
{
  imports = [ ./core.nix ];

  # Everything below is this laptop's Wayland desktop (niri) and GUI
  # software -- user-facing, but not portable to an arbitrary other machine
  # the way core.nix's shell/editor/dev tooling is. `fuzzel` and `git` are
  # deliberately not listed here even though an older flat package list had
  # them -- `git` comes from core.nix's `programs.git`, `fuzzel` from
  # `programs.fuzzel` below; listing either again would just be a redundant
  # duplicate.
  home.packages = with pkgs; [
    wob # services.wob below only wires the package in when systemd=true;
        # with systemd=false (see that block for why) it has to go here.
    ghostty

    swaybg
    wlsunset
    grim
    slurp
    playerctl
    brightnessctl
    pavucontrol
    networkmanagerapplet
    polkitAgentWrapper
    ghosttyTmuxAttach
    niriFloatSticky
    wl-clipboard
    libnotify
    xwayland-satellite # niri's Xwayland bridge -- see niri/config.kdl's
                        # spawn-at-startup.
    # catppuccin-cursors.latteLavender deliberately NOT listed here even though
    # it was in the old system package list -- catppuccin.cursors.enable
    # below already provides its own copy via home.pointerCursor.package,
    # and listing it again caused a real buildEnv conflict (two different
    # versions of the same package, since catppuccin/nix pins its own
    # cursor package separately from the top-level nixpkgs `pkgs` used
    # here). The *system*-level copy (needed for SDDM's pre-login greeter,
    # which home.packages can never reach) stays in
    # hosts/legion-laptop/configuration.nix -- genuinely different need,
    # not a duplicate of this one.

    google-chrome
    discord
    obsidian
    parsec-bin

    godot
    # Godot/GDScript tooling used by Neovim's godotdev.nvim integration and
    # available to Codex for verification from any Godot project directory.
    # godotdev.nvim prefers the fast GDQuest formatter; gdtoolkit supplies
    # gdlint plus gdformat as an alternative/CLI formatter.
    gdscript-formatter
    gdtoolkit_4
    blenderOffload
  ];

  # Procedurally generated (see dotfiles/wallpaper/generate.sh) rather than
  # downloaded, so it stays on-palette and has no license to track. Solid
  # color (`swaybg -c "#eff1f5"`) is the documented fallback in the niri
  # config if this ever needs reverting quickly.
  home.file.".local/share/wallpaper/catppuccin-latte.png".source =
    ./dotfiles/wallpaper/catppuccin-latte.png;

  # fuzzel moved to the real home-manager module (from plain xdg.configFile)
  # so catppuccin.fuzzel can merge its generated colors in via
  # `programs.fuzzel.settings` — see DECISIONS.md.
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        # "Iosevka Nerd Font" (no suffix) is Iosevka's default
        # quasi-proportional build -- the terminal (ghostty, formerly
        # WezTerm) forces it into a monospace terminal grid so it reads
        # as fixed-width there, but fuzzel renders it as a normal text
        # label using its own metrics, which looked visually different
        # from the terminal. "Mono" is the actual fixed-width cut -- see
        # DECISIONS.md. Size matched to the terminal's font-size (16)
        # too -- fuzzel was still on its original size=11, small enough
        # next to the terminal's 16 that the *same* monospace font read
        # as a different one at a glance.
        font = "Iosevka Nerd Font Mono:size=16";
        prompt = "❯";
        icon-theme = "Adwaita";
        terminal = "ghostty";
        layer = "overlay";
      };
      border = {
        width = 2;
        radius = 6;
      };
      dmenu.exit-immediately-if-empty = "yes";
    };
  };

  # Desktop shell replacing waybar/fuzzel/swaylock/swayidle -- see
  # niri/config.kdl for the `dms ipc call ...` binds that drive it
  # (spotlight, lock, control-center, notifications) and DECISIONS.md for
  # why. `niri.enableKeybinds`/`enableSpawn` deliberately left off: DMS's
  # own KDL-codegen has an open upstream bug on the flake+niri path that
  # leaves binds.kdl empty (AvengeMedia/DankMaterialShell#1586).
  # `systemd.enable` starts it as a user service instead.
  #
  # Idle timeout / auto-lock isn't a Nix option here -- one-time manual
  # pass through DMS's own settings panel after first login.
  #
  # `settings` is deliberately left unset: DMS's module writes it as a
  # full overwrite of ~/.config/DankMaterialShell/settings.json, not a
  # merge, and that file is live app state DMS keeps rewriting at runtime
  # (window layout, recents, etc) -- declaring even one key would reset
  # all of it back to just-what's-in-Nix on every rebuild. Stays fully
  # GUI-driven; Nix only controls install + running.
  #
  # The Catppuccin theme file (catppuccinDMSTheme above) is pinned but not
  # auto-activated, for the same reason. One-time manual step after
  # rebuild: DMS Settings -> Personalization -> Light Mode (Latte only
  # renders in light mode) -> Theme & Colors -> Custom -> pick the file
  # below -> flavor "Latte", accent "Lavender".
  programs.dank-material-shell = {
    enable = true;
    systemd.enable = true;
  };

  # Startup race fix for "DMS never started" on niri -- quickshell was
  # crashing before niri's Wayland socket existed yet, exhausting
  # systemd's restart-burst limit before ever getting a real retry. Full
  # story in DECISIONS.md. Both keys merge on top of the [Unit]/[Service]
  # DMS's own home-manager module generates -- no override needed since
  # neither is already set there.
  systemd.user.services.dms = {
    Unit = {
      StartLimitIntervalSec = 30;
      StartLimitBurst = 30;
    };
    Service.ExecStartPre = "${pkgs.writeShellScript "dms-wait-for-wayland" ''
      for _ in $(seq 1 50); do
        [ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ] && break
        sleep 0.1
      done
      exit 0
    ''}";
  };

  xdg.configFile."DankMaterialShell/themes/catppuccin.json".source =
    "${catppuccinDMSTheme}/catppuccin.json";

  # Spotify, themed via spicetify-nix (flake input) + catppuccin/spicetify
  # (the official Catppuccin org theme, not a third-party file like the
  # Blender one that turned out to be more trouble than it was worth --
  # see DECISIONS.md). Wraps the actual Spotify package with the theme
  # baked in at build time rather than the traditional spicetify-cli
  # "patch the installed app, re-run after every update" flow, so this
  # replaces the plain `spotify` package above rather than sitting
  # alongside it -- installing both would just double up the binary.
  # No `accentColor` option here: Catppuccin's theme provides the palette,
  # but the actual accent is picked from Spotify's own native settings
  # page (a small built-in feature, not something spicetify-nix exposes)
  # -- a manual one-time step, same class of thing as EasyEffects' input
  # device selection.
  programs.spicetify = {
    enable = true;
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "latte";

    # catppuccin/spicetify's user.css only themes the left-hand transport
    # controls in the now-playing bar (shuffle/play/skip/heart/progress) --
    # confirmed by grepping the theme's built user.css, there isn't a
    # single rule for the right-hand icons (volume, queue, connect-device,
    # lyrics, fullscreen). Those fall back to Spotify's own default icon
    # color, tuned for its native black UI, which reads as washed-out
    # against Latte's light background -- reported as "hard to see" at the
    # bottom of the window. Rather than guess Spotify's obfuscated,
    # version-specific class names for each of those icons individually,
    # this targets every icon in the bar broadly (data-testid selectors are
    # far more stable across Spotify updates than class names) with the
    # same colors the theme already uses for the covered buttons.
    enabledSnippets = [
      ''
        :root .Root__now-playing-bar button svg,
        :root .Root__now-playing-bar [role="slider"] svg {
          fill: var(--spice-subtext) !important;
        }
        :root .Root__now-playing-bar button:hover svg,
        :root .Root__now-playing-bar [role="slider"]:hover svg {
          fill: var(--spice-text) !important;
        }
      ''
    ];
  };

  # wob: on-screen volume/brightness popup. No catppuccin.nix module for it,
  # so colors are hand-applied Catppuccin Latte hex (matches niri's border
  # colors — see DECISIONS.md). `systemd = false` because this desktop never set up
  # systemd session integration for niri (everything else is spawned
  # directly by the compositor, not systemd-activated) -- wob is started the
  # same way, piping into a hand-made FIFO instead of wob's socket unit.
  services.wob = {
    enable = true;
    systemd = false;
    settings = {
      "" = {
        timeout = 1000;
        max = 100;
        width = 300;
        height = 24;
        border_offset = 4;
        border_size = 2;
        bar_padding = 4;
        anchor = "bottom";
        margin = 48;
        border_color = "acb0beff";
        background_color = "e6e9efff";
        bar_color = "7287fdff";
      };
      "style.muted".bar_color = "d20f39ff";
    };
  };

  # System-level mic noise suppression via PipeWire (RNNoise +
  # DeepFilterNet), not Discord's own Krisp -- Krisp is broken on NixOS
  # (the patched Discord binary fails Krisp's integrity check) and this
  # benefits every app, not just Discord. See DECISIONS.md for the
  # Krisp/DeepFilterNet history. `programs.dconf.enable` (configuration.nix)
  # is a required system-level companion for state persistence.
  #
  # Still needs one manual, per-app step after rebuilding: pick the
  # EasyEffects-processed source as the input device in each app (e.g.
  # Discord's Voice & Video settings) -- PipeWire routing is runtime
  # state, not something Nix can set once.
  services.easyeffects = {
    enable = true;
    preset = "mic-denoise";
    extraPresets = {
      mic-denoise = {
        input = {
          "plugins_order" = [ "rnnoise#0" "deepfilternet#0" ];
          "rnnoise#0" = {
            bypass = false;
            "enable-vad" = false;
            "input-gain" = 0.0;
            "model-path" = "";
            "output-gain" = 0.0;
            release = 20.0;
            "vad-thres" = 50.0;
            wet = 0.0;
          };
          "deepfilternet#0" = {
            bypass = false;
            "input-gain" = 0.0;
            "output-gain" = 0.0;
            "post-filter-beta" = 0.02;
          };
        };
      };
    };
  };

  # catppuccin.cursors sets home.pointerCursor.name/.package but not .enable
  # (upstream gap) -- home-manager now requires this explicitly or it's a
  # deprecation warning on every rebuild.
  home.pointerCursor.enable = true;

  # `enable`/`flavor`/`accent`/`starship.enable` come from core.nix -- these
  # are the desktop-only flavors of catppuccin theming, for GUI programs
  # that only exist in this file.
  catppuccin = {
    fuzzel.enable = true;
    gtk.icon.enable = true;
    cursors.enable = true;
    # niri stays hand-applied — see DECISIONS.md for why.
  };

  gtk.enable = true;

  # catppuccin.nix's own gtk module only covers icons (Papirus, already
  # wired via catppuccin.gtk.icon.enable above) -- it has no widget/color
  # theme option, so without this, GTK apps (pavucontrol, nm-applet, any
  # file manager added later) render in default Adwaita instead of
  # Catppuccin. catppuccin/gtk is a separate upstream project, packaged in
  # nixpkgs as catppuccin-gtk.
  gtk.theme = {
    name = "catppuccin-latte-lavender-standard";
    package = pkgs.catppuccin-gtk.override {
      accents = [ "lavender" ];
      variant = "latte";
    };
  };
  # Explicit rather than relying on the stateVersion-gated legacy default --
  # this is exactly the legacy behavior (GTK4 apps use the same gtk.theme),
  # just without the "your default will change later" warning on every build.
  gtk.gtk4.theme = config.gtk.theme;

  xdg.configFile = {
    "ghostty".source = ./dotfiles/ghostty;
    "niri".source = ./dotfiles/niri;
    "scripts".source = ./dotfiles/scripts;
  };
}
