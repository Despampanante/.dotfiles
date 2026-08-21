# Portable subset of home-manager config: shell, git, neovim, tmux, and CLI
# dev tooling that makes sense on any machine. This laptop's actual desktop
# (niri, DankMaterialShell, GPU offload wrappers, browser/Discord/etc) lives
# in santi.nix instead, which imports this file for its own NixOS use.
# Also wired up standalone as `homeConfigurations.santi` in flake.nix, for
# machines that aren't running this flake's NixOS config at all --
# `home-manager switch --flake ~/dotfiles/nixos#santi`.
#
# Config files under ./dotfiles referenced here (and, where noted in
# DECISIONS.md, recolored) are pulled from
# https://github.com/Despampanante/.dotfiles -- deliberately kept as plain
# dotfiles rather than rewritten into home-manager's structured options, so
# they stay usable as-is on Windows too (via chezmoi, per that repo's setup).

{ pkgs, ... }:

let
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
      # unchanged if another host is ever added -- see DECISIONS.md. No-ops
      # (harmlessly) on a machine that isn't running this flake's NixOS
      # config at all.
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

  # Catppuccin theming -- only the `starship` flavor here, since that's the
  # only catppuccin-themed thing this portable subset installs (the named
  # colors in programs.starship.settings above, like "lavender"/"mauve",
  # only resolve through the palette this module generates). Desktop-only
  # flavors (fuzzel, gtk, cursors) stay in santi.nix, next to the GUI
  # programs they theme.
  catppuccin = {
    enable = true;
    autoEnable = false;
    flavor = "latte";
    accent = "lavender";

    starship.enable = true;
  };

  home.packages = with pkgs; [
    fzf # needed by tmux-sessionizer
    ripgrep
    tmux
    claude-code
    codex
    jq

    gh
    lazygit
    vim
    neovim
    wget

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
  ];

  home.file.".local/bin/tmux-sessionizer" = {
    source = ./dotfiles/bin/tmux-sessionizer;
    executable = true;
  };

  home.file.".config/tmux/plugins/tpm".source = tpm;

  xdg.configFile = {
    "nvim".source = ./dotfiles/nvim;
    # Per-file, not whole-directory -- leaves ~/.config/tmux/plugins/ free
    # for TPM's own imperative plugin clones to live alongside the
    # Nix-managed tpm symlink (home.file above), same reasoning as
    # santi.nix's fuzzel/swaylock restructuring (see DECISIONS.md).
    "tmux/tmux.conf".source = ./dotfiles/tmux/tmux.conf;
    "tmux-sessionizer".source = ./dotfiles/tmux-sessionizer;
    "opensessions/config.json".source = ./dotfiles/opensessions/config.json;
  };
}
