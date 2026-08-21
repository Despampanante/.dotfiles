# Host: TEMPLATE -- not wired into flake.nix yet. Forked from
# hosts/legion-laptop/configuration.nix for a second NixOS machine sharing
# the same home/santi.nix desktop. See DECISIONS.md for the reasoning
# behind options kept here unchanged.
#
# Before this is usable:
#   1. Rename this directory (hosts/new-machine -> hosts/<real-name>) and
#      update networking.hostName below to match.
#   2. Boot a NixOS installer on the real machine and run
#      `nixos-generate-config` (or `--root /mnt` from the installer media),
#      then copy the `hardware-configuration.nix` it writes into this
#      directory -- it doesn't exist yet, and can't be faked or copied from
#      legion-laptop; it's read straight off that machine's actual
#      disks/CPU/kernel modules.
#   3. Read every section below marked REVIEW -- these depend on hardware
#      legion-laptop has that this machine may not (NVIDIA hybrid graphics,
#      dual-boot Windows, gaming).
#   4. Uncomment this host's block in flake.nix (see the comment there) and
#      point it at this directory.

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # REVIEW: legion-laptop uses systemd-boot for UEFI dual-boot with Windows.
  # `nixos-generate-config`'s own suggested boot.loader block (in the
  # configuration.nix it writes on the real machine) is usually the right
  # thing to use here instead, if this machine boots differently.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # REVIEW: pick a real, unique hostname -- must be valid per RFC1123 (no
  # underscores; see legion-laptop's config for the story on why that
  # matters) and match whatever key this host gets in flake.nix.
  networking.hostName = "new-machine";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/New_York";
  # REVIEW: legion-laptop sets this only because it dual-boots Windows on
  # the same hardware clock (Windows assumes the RTC is local time, Linux
  # assumes UTC by default). Delete this line entirely if this machine is
  # NixOS-only.
  time.hardwareClockInLocalTime = true;

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

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  catppuccin = {
    enable = true;
    autoEnable = false;
    flavor = "latte";
    accent = "lavender";
    sddm.enable = true;
  };

  # SDDM's greeter has no cursor at all without this -- catppuccin.cursors
  # in home/santi.nix only reaches the logged-in session, not the greeter.
  # Same four-piece setup as legion-laptop; see DECISIONS.md ("SDDM greeter
  # cursor") for why each piece is needed on its own.
  environment.variables = {
    XCURSOR_THEME = "catppuccin-latte-lavender-cursors";
    XCURSOR_SIZE = "32";
  };

  services.displayManager.sddm.settings.General.GreeterEnvironment =
    "XCURSOR_THEME=catppuccin-latte-lavender-cursors;XCURSOR_PATH=${pkgs.catppuccin-cursors.latteLavender}/share/icons";

  services.displayManager.sddm.settings.Theme = {
    CursorTheme = "catppuccin-latte-lavender-cursors";
    CursorSize = 32;
  };

  services.displayManager.sddm.wayland.compositorCommand =
    let
      westonIni = (pkgs.formats.ini { }).generate "weston.ini" {
        core = {
          cursor-theme = "catppuccin-latte-lavender-cursors";
          cursor-size = 32;
        };
        libinput = {
          enable-tap = config.services.libinput.mouse.tapping;
          left-handed = config.services.libinput.mouse.leftHanded;
        };
        keyboard = {
          keymap_model = config.services.xserver.xkb.model;
          keymap_layout = config.services.xserver.xkb.layout;
          keymap_variant = config.services.xserver.xkb.variant;
          keymap_options = config.services.xserver.xkb.options;
        };
      };
      westonWrapper = pkgs.writeShellScript "sddm-weston-wrapper" ''
        export XCURSOR_PATH="${pkgs.catppuccin-cursors.latteLavender}/share/icons"
        exec ${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}
      '';
    in
    "${westonWrapper}";

  # REVIEW: only relevant if this machine is for gaming too -- delete this
  # whole block if not. legion-laptop's version also sets NVIDIA PRIME
  # offload env vars matching hardware.nvidia below, which don't apply here.
  # programs.steam = {
  #   enable = true;
  #   remotePlay.openFirewall = true;
  #   localNetworkGameTransfers.openFirewall = true;
  # };

  programs.niri.enable = true;

  # Session save/restore for niri -- see legion-laptop's config /
  # DECISIONS.md for the full story. `settings.launch` maps a window's
  # Wayland app_id to the real binary name to relaunch it with; only needed
  # for apps that don't share a name with their app_id (like Ghostty here,
  # relaunched via the tmux-attach wrapper from home/santi.nix instead of
  # bare `ghostty`).
  services.nirinit = {
    enable = true;
    settings.skip.apps = [ ];
    settings.launch = {
      "Spotify" = "spotify";
      "md.Obsidian" = "obsidian";
      "com.mitchellh.ghostty" = "ghostty-tmux-attach";
    };
  };

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

  # Needed for niri to get a working GL context at all, regardless of GPU.
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # REVIEW: legion-laptop's whole `hardware.nvidia` block (hybrid AMD+NVIDIA
  # PRIME offload, bus IDs from that machine's own `lspci` output) is
  # deliberately NOT copied here -- it's specific to that laptop's exact GPU
  # pairing and would be wrong (or just inert) on different hardware.
  #
  # If this machine has an NVIDIA GPU (hybrid or not), work out its own
  # `hardware.nvidia` config from what `nixos-generate-config` detects plus
  # the NixOS wiki, rather than copy-pasting legion-laptop's bus IDs.
  #
  # If this machine has no NVIDIA GPU at all: leave `hardware.nvidia` and
  # `services.xserver.videoDrivers` unset, AND remove `blenderOffload` from
  # home/santi.nix's home.packages for this host somehow (that package
  # hardcodes a call to the `nvidia-offload` command, which only exists
  # because legion-laptop's `hardware.nvidia.prime.offload.enableOffloadCmd`
  # puts it on PATH -- it'll build fine here but fail at *runtime*,
  # "command not found", without that). Since home/santi.nix is currently
  # shared unmodified across hosts, the cleanest fix if this comes up is
  # splitting blenderOffload out into a legion-laptop-only package list.
  # services.xserver.videoDrivers = [ "nvidia" ];

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

  # Required by home-manager's services.easyeffects (home/santi.nix) -- the
  # daemon needs dconf/gsettings to persist its own state.
  programs.dconf.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Everything user-facing (desktop apps, dev tooling, LSPs) lives in
  # home.packages (home/core.nix + home/santi.nix) instead -- system-level
  # config here stays focused on hardware/drivers/daemons/boot.
  #
  # This one exception stays here, same as legion-laptop: SDDM's pre-login
  # greeter reads XCURSOR_THEME/the weston.ini cursor-theme setting above
  # against the *system* profile (/run/current-system/sw/share/icons) --
  # home.packages only ever reaches the user profile, which doesn't exist
  # yet at greeter time, so this can't move with everything else.
  environment.systemPackages = [ pkgs.catppuccin-cursors.latteLavender ];

  # REVIEW: set to whatever release `nixos-generate-config`'s own fresh
  # configuration.nix wrote on this machine -- tracks *this host's* first
  # install, not legion-laptop's.
  system.stateVersion = "26.05";
}
