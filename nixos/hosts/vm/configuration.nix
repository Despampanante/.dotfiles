# Host: vm (VirtualBox guest, used to build up this config before migrating
# to the laptop). See ../../DECISIONS.md for the reasoning behind the
# choices below.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader. VM-specific (legacy BIOS + /dev/sda) — the laptop will need
  # UEFI + systemd-boot (or GRUB in EFI mode) to dual-boot with Windows.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "vm";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Keyboard layout data (used by Wayland/console too, not just X).
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Two Wayland tiling WMs, both selectable at the SDDM login screen —
  # replaces the original KDE Plasma default. Sway (mature, i3-compatible,
  # config fully built out) and niri (newer scrollable-tiling model, config
  # is a first draft — see home/dotfiles/niri/config.kdl) side by side so
  # niri can actually be tried before committing to it over sway.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # System-level catppuccin.nix (separate from the home-manager one in
  # home/santi.nix -- SDDM runs pre-login, outside any user session, so it
  # needs the NixOS module instead). Matches the desktop's Catppuccin Latte
  # theming everywhere else -- see DECISIONS.md.
  catppuccin = {
    enable = true;
    # Same reasoning as home/santi.nix's autoEnable=false: without it, this
    # silently themes *every* catppuccin-supported NixOS module (caught
    # GRUB getting auto-themed on the first build here, unasked-for) --
    # opt in per-module instead.
    autoEnable = false;
    flavor = "latte";
    accent = "peach";
    sddm.enable = true;
  };

  # SDDM's greeter has no cursor at all without this -- catppuccin.cursors
  # in home/santi.nix only applies inside the logged-in user's session, same
  # split as the GTK/SDDM theming above. Value confirmed by building
  # catppuccin-cursors.lattePeach and checking share/icons/ directly.
  environment.variables = {
    XCURSOR_THEME = "catppuccin-latte-peach-cursors";
    XCURSOR_SIZE = "32";
  };

  # Steam gets the dedicated NixOS module rather than just the package --
  # it also pulls in 32-bit graphics libs and (with these two flags) opens
  # firewall ports for Remote Play and Local Network Game Transfers, which
  # a plain `pkgs.steam` in environment.systemPackages wouldn't set up.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      sway-contrib.grimshot # sway-specific: shells out to swaymsg
    ];
  };
  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  fonts.packages = with pkgs; [
    iosevka
    nerd-fonts.iosevka
  ];

  services.printing.enable = true;
  hardware.bluetooth.enable = true;

  # Needed for sway/niri (both wlroots-based) to get a working GL context at
  # all — without this, Mesa/EGL isn't set up and the compositor crashes
  # right after SDDM hands off to it (symptom: SDDM login works, but you land
  # on a blank console with a blinking cursor after picking a session).
  hardware.graphics.enable = true;

  # VirtualBox's virtual GPU doesn't support hardware cursor planes, which
  # crashes wlroots compositors without this — the standard workaround for
  # sway/niri under VirtualBox.
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.santi = {
    isNormalUser = true;
    description = "Santi";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  programs.firefox.enable = true;

  # Needed for google-chrome/discord/obsidian/spotify below and Steam
  # above. A predicate limited to just those package names would be more
  # precise, but Steam alone pulls in several differently-named unfree
  # derivations under the hood (steam-unwrapped, steam-run, etc.) that
  # shift between nixpkgs versions -- not worth the whack-a-mole for a
  # system that's going to run this much closed-source software anyway.
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    gh
    vim
    neovim
    wget
    wezterm

    # Python + C++ dev tooling
    python3
    python3Packages.pip
    gcc
    clang
    cmake
    gnumake
    gdb

    # Language servers for neovim's vim.lsp.enable() (see
    # nvim/plugin/40_plugins.lua) -- these are separate from the compilers
    # above (an LSP talks LSP, a compiler doesn't). Nix-managed rather than
    # through the mason.nvim already in the neovim config, since Mason
    # downloads prebuilt binaries that expect standard FHS paths and tends
    # to fight NixOS without extra glue (nix-ld) -- see DECISIONS.md.
    nixd # nix (this repo)
    lua-language-server # lua (the neovim config itself)
    pyright # python
    clang-tools # c/c++ -- also provides clangd
    bash-language-server # bash (sway/niri/waybar scripts)
    tree-sitter # CLI nvim-treesitter needs to build parsers it doesn't
                # bundle (e.g. gdscript) -- was missing outright, so that
                # install silently failed and retried on every nvim launch

    # Desktop pieces shared between the sway and niri sessions (not
    # sway-specific despite some package names — swaylock/swayidle/waybar
    # etc. work under any wlr-layer-shell-capable compositor).
    waybar
    fuzzel
    swaynotificationcenter
    swaylock
    swayidle
    swaybg
    wlsunset
    grim
    slurp
    playerctl
    brightnessctl
    pavucontrol
    networkmanagerapplet
    polkit_gnome
    wl-clipboard
    libnotify
    xwayland-satellite # niri's Xwayland bridge -- see niri/config.kdl's
                        # spawn-at-startup. Not needed for sway, which has
                        # Xwayland support built in via wlroots.
    catppuccin-cursors.lattePeach # so XCURSOR_THEME above actually
                                   # resolves to something on the system
                                   # (not just home-manager's) XDG data dirs

    # Regular apps. Steam is separate (programs.steam above) since it
    # needs more than just the package.
    google-chrome
    discord
    obsidian
    spotify
  ];

  system.stateVersion = "25.05";
}
