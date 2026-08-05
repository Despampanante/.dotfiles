# Home-manager config for santi. Config files under ./dotfiles are pulled
# (and, where noted in DECISIONS.md, recolored) from
# https://github.com/Despampanante/.dotfiles — deliberately kept as plain
# dotfiles rather than rewritten into home-manager's structured options, so
# they stay usable as-is on Windows too (via chezmoi, per that repo's setup).

{ config, pkgs, ... }:

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
      nrs = "sudo nixos-rebuild switch --flake ~/dotfiles/nixos#vm";
      nrb = "sudo nixos-rebuild build --flake ~/dotfiles/nixos#vm";
    };
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
  ];

  home.file.".local/bin/tmux-sessionizer" = {
    source = ./dotfiles/bin/tmux-sessionizer;
    executable = true;
  };

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
        # renders it as a normal text label using its natural (slightly
        # variable-width) spacing, which looked visually different from
        # the terminal. "Mono" is the actual fixed-width cut -- see
        # DECISIONS.md.
        font = "Iosevka Nerd Font Mono:size=11";
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
  # so colors are hand-applied Catppuccin Latte hex (matches swaync/sway/niri
  # — see DECISIONS.md). `systemd = false` because this desktop never set up
  # systemd session integration for sway/niri (everything else is spawned
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
    # sway/niri/swaync stay hand-applied — see DECISIONS.md for why.
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
    "palette.json".source = ./dotfiles/palette.json;
    "nvim".source = ./dotfiles/nvim;
    "tmux".source = ./dotfiles/tmux;
    "wezterm".source = ./dotfiles/wezterm;
    "sway".source = ./dotfiles/sway;
    "niri".source = ./dotfiles/niri;
    "swaync".source = ./dotfiles/swaync;
    "scripts".source = ./dotfiles/scripts;
  };
}
