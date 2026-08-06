# Home-manager config for santi. Config files under ./dotfiles are pulled
# (and, where noted in DECISIONS.md, recolored) from
# https://github.com/Despampanante/.dotfiles — deliberately kept as plain
# dotfiles rather than rewritten into home-manager's structured options, so
# they stay usable as-is on Windows too (via chezmoi, per that repo's setup).

{ config, pkgs, ... }:

let
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

  # Prompt. Colors reference catppuccin/nix's generated palette (peach/mauve/
  # red/green — see DECISIONS.md), merged in via catppuccin.starship below.
  # enableZshIntegration defaults to true, so this hooks into programs.zsh
  # above automatically.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$directory$git_branch$git_status$character";

      directory = {
        style = "bold peach";
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
    # for. `fuzzel`, `swaylock`, `waybar`, and `git` are deliberately not
    # listed even though the old system list had them -- they're already
    # installed by their own `programs.<app>.enable` modules below/in
    # waybar.nix, listing them again would just be a redundant duplicate.
    gh
    vim
    neovim
    wget
    wezterm

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

    swaynotificationcenter
    swayidle
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
    # catppuccin-cursors.lattePeach deliberately NOT listed here even though
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
    spotify
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

  imports = [ ./waybar.nix ./wlogout.nix ];

  # fuzzel and swaylock moved to the real home-manager modules (from plain
  # xdg.configFile) so catppuccin.fuzzel/catppuccin.swaylock can merge their
  # generated colors in via `programs.<app>.settings` — see DECISIONS.md.
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        # "Iosevka Nerd Font" (no suffix) is Iosevka's default
        # quasi-proportional build -- WezTerm forces it into a monospace
        # terminal grid so it reads as fixed-width there, but fuzzel
        # renders it as a normal text label using its own metrics, which
        # looked visually different from the terminal. "Mono" is the
        # actual fixed-width cut -- see DECISIONS.md. Size matched to
        # WezTerm's font_size (16) too -- fuzzel was still on its
        # original size=11, small enough next to the terminal's 16 that
        # the *same* monospace font read as a different one at a glance.
        font = "Iosevka Nerd Font Mono:size=16";
        prompt = "❯";
        icon-theme = "Adwaita";
        terminal = "wezterm";
        layer = "overlay";
      };
      border = {
        width = 2;
        radius = 6;
      };
      dmenu.exit-immediately-if-empty = "yes";
    };
  };

  programs.swaylock = {
    enable = true;
    settings = {
      indicator-caps-lock = true;
      font = "Iosevka Nerd Font";
      font-size = 20;
      indicator-radius = 115;
    };
  };

  # wob: on-screen volume/brightness popup. No catppuccin.nix module for it,
  # so colors are hand-applied Catppuccin Latte hex (matches swaync/niri —
  # see DECISIONS.md). `systemd = false` because this desktop never set up
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
        bar_color = "fe640bff";
      };
      "style.muted".bar_color = "d20f39ff";
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
    accent = "peach";

    fuzzel.enable = true;
    swaylock.enable = true;
    starship.enable = true;
    gtk.icon.enable = true;
    cursors.enable = true;
    # waybar is enabled in ./waybar.nix, next to the rest of its config.
    # niri/swaync stay hand-applied — see DECISIONS.md for why.
  };

  gtk.enable = true;

  # catppuccin.nix's own gtk module only covers icons (Papirus, already
  # wired via catppuccin.gtk.icon.enable above) -- it has no widget/color
  # theme option, so without this, GTK apps (pavucontrol, nm-applet, any
  # file manager added later) render in default Adwaita instead of
  # Catppuccin. catppuccin/gtk is a separate upstream project, packaged in
  # nixpkgs as catppuccin-gtk.
  gtk.theme = {
    name = "catppuccin-latte-peach-standard";
    package = pkgs.catppuccin-gtk.override {
      accents = [ "peach" ];
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
    # same reasoning as the earlier waybar/fuzzel/swaylock restructuring.
    "tmux/tmux.conf".source = ./dotfiles/tmux/tmux.conf;
    "wezterm".source = ./dotfiles/wezterm;
    "niri".source = ./dotfiles/niri;
    "swaync".source = ./dotfiles/swaync;
    "scripts".source = ./dotfiles/scripts;
  };
}
