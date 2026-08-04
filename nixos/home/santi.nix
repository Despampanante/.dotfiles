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
  ];

  home.file.".local/bin/tmux-sessionizer" = {
    source = ./dotfiles/bin/tmux-sessionizer;
    executable = true;
  };

  imports = [ ./waybar.nix ];

  # fuzzel and swaylock moved to the real home-manager modules (from plain
  # xdg.configFile) so catppuccin.fuzzel/catppuccin.swaylock can merge their
  # generated colors in via `programs.<app>.settings` — see DECISIONS.md.
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "Iosevka Nerd Font:size=11";
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

  xdg.configFile = {
    "palette.json".source = ./dotfiles/palette.json;
    "nvim".source = ./dotfiles/nvim;
    "tmux".source = ./dotfiles/tmux;
    "wezterm".source = ./dotfiles/wezterm;
    "sway".source = ./dotfiles/sway;
    "niri".source = ./dotfiles/niri;
    "swaync".source = ./dotfiles/swaync;
  };
}
