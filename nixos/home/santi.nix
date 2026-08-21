# Home-manager config for santi. Config files under ./dotfiles are pulled
# (and, where noted in DECISIONS.md, recolored) from
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

  # TPM (tmux plugin manager) itself, fetched declaratively -- discovered
  # while wiring up catppuccin/tmux that ~/.config/tmux/plugins/ didn't
  # exist at all (confirmed live), meaning TPM had never actually been
  # bootstrapped and no tmux plugin has ever loaded, before or after this
  # change. The usual TPM setup expects a manual `git clone` as a one-time
  # step; fetching it here instead means it's always present after a
  # rebuild, no manual bootstrap needed. TPM itself still imperatively
  # clones whatever plugins are `set -g @plugin`'d (catppuccin/tmux here)
  # as sibling directories under plugins/ on first run/prefix+I -- that
  # part isn't Nix-managed, same as any other TPM setup.
  tpm = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tpm";
    rev = "e261deb1b47614eed3400089ce7197dc68acc4eb";
    sha256 = "1c4s1maismj0l297vhnxkc309mcn4936q7z4j7jhaqc9vij984m1";
  };

  # Catppuccin's official DankMaterialShell theme -- bundles all four
  # flavors (Latte/Frappé/Macchiato/Mocha) in one catppuccin.json, picked
  # inside DMS itself (see xdg.configFile below for where it's placed).
  # Fetched declaratively rather than the upstream "download the file by
  # hand" instructions, same reasoning as tpm above.
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
  home.username = "santi";
  home.homeDirectory = "/home/santi";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = "Santi";
      email = "santiago.depascale@gmail.com";
    };
    # Lets `git push`/`pull` over HTTPS use `gh`'s stored auth instead of
    # failing with "could not read Username" -- ~/.config/git/config is
    # home-manager-managed (read-only), so `gh auth setup-git` can't write
    # to it directly; setting this here is the equivalent for this repo.
    settings.credential.helper = "!gh auth git-credential";
    # mini.sessions' local-session file (see nvim/plugin/30_mini.lua) lands
    # directly in a project's cwd as `Session.vim` -- global ignore instead
    # of expecting every repo (most not even mine) to carry its own entry.
    ignores = [ "Session.vim" ];
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    history.size = 10000;
    shellAliases = {
      ll = "ls -la";
      la = "ls -A";
      gs = "git status";
      # $(hostname) rather than a hardcoded host name so these keep working
      # unchanged if another host is ever added -- see DECISIONS.md.
      nrs = "sudo nixos-rebuild switch --flake ~/dotfiles/nixos#$(hostname)";
      nrb = "sudo nixos-rebuild build --flake ~/dotfiles/nixos#$(hostname)";
    };
  };

  # Per-project dev environments (e.g. a C++ project's flake.nix pulling in
  # Eigen/Boost/fmt/Catch2/ninja) rather than piling project-specific
  # libraries into system.systemPackages -- see DECISIONS.md. nix-direnv
  # adds a build-output cache on top of plain direnv, so `nix develop`'s
  # shell doesn't get fully re-evaluated on every `cd`. enableZshIntegration
  # defaults to true, hooking into programs.zsh above automatically.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Prompt. Colors reference catppuccin/nix's generated palette (lavender/
  # mauve/red/green — see DECISIONS.md), merged in via catppuccin.starship
  # below. `directory` specifically tracks the global accent (lavender) --
  # git_branch/git_status/character stay mauve/red/green regardless of
  # accent, a separate deliberate multi-color choice, not accent-linked.
  # enableZshIntegration defaults to true, so this hooks into programs.zsh
  # above automatically.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$directory$git_branch$git_status$character";

      directory = {
        style = "bold lavender";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        style = "mauve";
        format = "[ $symbol$branch]($style)";
        symbol = " ";
      };

      git_status = {
        style = "red";
        format = "[$all_status$ahead_behind]($style)";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
    };
  };

  home.packages = with pkgs; [
    fzf # needed by tmux-sessionizer
    ripgrep
    tmux
    wob # services.wob below only wires the package in when systemd=true;
        # with systemd=false (see that block for why) it has to go here.
    claude-code
    jq # needed by scripts/window-switcher.sh to parse `niri msg -j windows`

    # Everything below used to live in environment.systemPackages on the
    # host -- moved here since it's all user-facing software, not
    # system-level (drivers/daemons/boot), which is what home-manager is
    # for. `fuzzel` and `git` are deliberately not listed even though the
    # old system list had them -- they're already installed by their own
    # `programs.<app>.enable` modules below, listing them again would just
    # be a redundant duplicate.
    gh
    vim
    neovim
    wget
    ghostty

    python3
    python3Packages.pip
    # hiPrio on gcc: home-manager's home.packages buildEnv (unlike
    # environment.systemPackages, which tolerates this) fails outright on
    # gcc and clang both providing bin/ld.bfd -- confirmed via a real build
    # error ("two given paths contain a conflicting subpath"), not a
    # hypothetical. This keeps both compilers fully available under their
    # own gcc/clang/clang++ names, just lets gcc's copy of the generic
    # ld.bfd win the conflict.
    (pkgs.lib.hiPrio gcc)
    clang
    cmake
    gnumake
    gdb

    nixd
    lua-language-server
    pyright
    clang-tools
    bash-language-server
    tree-sitter

    swaybg
    wlsunset
    grim
    slurp
    playerctl
    brightnessctl
    pavucontrol
    networkmanagerapplet
    polkitAgentWrapper
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
    blenderOffload
  ];

  home.file.".local/bin/tmux-sessionizer" = {
    source = ./dotfiles/bin/tmux-sessionizer;
    executable = true;
  };

  home.file.".config/tmux/plugins/tpm".source = tpm;

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

  catppuccin = {
    enable = true;
    autoEnable = false;
    flavor = "latte";
    accent = "lavender";

    fuzzel.enable = true;
    starship.enable = true;
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
    "nvim".source = ./dotfiles/nvim;
    # Per-file, not whole-directory, unlike the others below -- leaves
    # ~/.config/tmux/plugins/ free for TPM's own imperative plugin clones
    # to live alongside the Nix-managed tpm symlink (home.file above),
    # same reasoning as the earlier fuzzel/swaylock restructuring.
    "tmux/tmux.conf".source = ./dotfiles/tmux/tmux.conf;
    "ghostty".source = ./dotfiles/ghostty;
    "niri".source = ./dotfiles/niri;
    "scripts".source = ./dotfiles/scripts;
  };
}
