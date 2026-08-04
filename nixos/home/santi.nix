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

  # Prompt, themed to match palette.json's warm-light colors (accent/purple/
  # red/green — see nixos/DECISIONS.md). enableZshIntegration defaults to
  # true, so this hooks into programs.zsh above automatically.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      format = "$directory$git_branch$git_status$character";

      directory = {
        style = "bold #7e5701"; # accent
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        style = "#570056"; # purple
        format = "[ $symbol$branch]($style)";
        symbol = " ";
      };

      git_status = {
        style = "#6d0022"; # red
        format = "[$all_status$ahead_behind]($style)";
      };

      character = {
        success_symbol = "[❯](bold #005f24)"; # green
        error_symbol = "[❯](bold #6d0022)"; # red
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

  xdg.configFile = {
    "palette.json".source = ./dotfiles/palette.json;
    "nvim".source = ./dotfiles/nvim;
    "tmux".source = ./dotfiles/tmux;
    "wezterm".source = ./dotfiles/wezterm;
    "sway".source = ./dotfiles/sway;
    "niri".source = ./dotfiles/niri;
    "waybar".source = ./dotfiles/waybar;
    "fuzzel".source = ./dotfiles/fuzzel;
    "swaync".source = ./dotfiles/swaync;
    "swaylock".source = ./dotfiles/swaylock;
  };
}
