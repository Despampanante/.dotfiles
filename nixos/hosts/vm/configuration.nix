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

    # Desktop pieces shared between the sway and niri sessions (not
    # sway-specific despite some package names — swaylock/swayidle/waybar
    # etc. work under any wlr-layer-shell-capable compositor).
    waybar
    fuzzel
    swaynotificationcenter
    swaylock
    swayidle
    swaybg
    grim
    slurp
    playerctl
    brightnessctl
    pavucontrol
    networkmanagerapplet
    polkit_gnome
    wl-clipboard
    libnotify
  ];

  system.stateVersion = "25.05";
}
