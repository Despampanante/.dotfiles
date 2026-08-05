# Host: legion-laptop (Lenovo Legion 5 17ACH6H, dual-booting Windows). See
# ../../DECISIONS.md for the reasoning behind the choices below, and the
# "legion-laptop host" entry for what's laptop-specific vs. carried over
# from hosts/vm as-is.

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # UEFI (systemd-boot), not vm's legacy-BIOS GRUB — required to dual-boot
  # Windows, and what nixos-generate-config detected on the real hardware.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Replaces the invalid "legion_laptop" hostname from the initial install
  # (underscores aren't valid in a hostname per RFC1123 — NixOS built it
  # anyway but the kernel/systemd silently dropped the underscore at
  # runtime, so `hostname` returned "legionlaptop" while /etc/hostname still
  # said "legion_laptop"). Picked "legion-laptop" (hyphen, valid) over
  # matching the live "legionlaptop" — since neither matches what's
  # currently running, this needs an actual `nrs` + reboot/relogin to take
  # effect; `/etc/hostname` won't self-correct without it.
  networking.hostName = "legion-laptop";
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

  # Same sway/niri dual setup as hosts/vm -- see DECISIONS.md.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  catppuccin = {
    enable = true;
    autoEnable = false;
    flavor = "latte";
    accent = "peach";
    sddm.enable = true;
  };

  # SDDM's greeter has no cursor at all without this -- catppuccin.cursors
  # in home/santi.nix only applies inside the logged-in user's session (via
  # home-manager), which SDDM runs entirely outside of, same split as the
  # GTK/SDDM theming above. XCURSOR_THEME here has to match the folder name
  # home-manager's pointerCursor resolves to (confirmed by building
  # catppuccin-cursors.lattePeach and checking share/icons/ directly, same
  # as how the GTK theme name was confirmed rather than guessed).
  #
  # Turned out not to be enough on its own: `systemctl show sddm.service -p
  # Environment` came back completely empty even with this set, and more
  # fundamentally the actual visible mouse pointer is drawn by SDDM's
  # Wayland greeter's own embedded Weston compositor (`[Wayland]
  # CompositorCommand` in /etc/sddm.conf.d -- confirmed by reading the
  # NixOS sddm module source), not by anything reading XCURSOR_THEME
  # directly. The module only auto-sets `[Theme] CursorTheme` for the
  # default "breeze" theme (we override to catppuccin), and even then
  # never forwards it into the Weston config it generates -- Weston's own
  # weston.ini needs its own `[core] cursor-theme`/`cursor-size`, which the
  # module doesn't expose at all. Overriding `compositorCommand` (marked
  # `internal` in the module, but a real settable mkOption) with our own
  # weston.ini that adds that section -- mirrors the module's own
  # weston.ini generation for libinput/keyboard so nothing else regresses.
  environment.variables = {
    XCURSOR_THEME = "catppuccin-latte-peach-cursors";
    XCURSOR_SIZE = "32";
  };

  services.displayManager.sddm.wayland.compositorCommand =
    let
      westonIni = (pkgs.formats.ini { }).generate "weston.ini" {
        core = {
          cursor-theme = "catppuccin-latte-peach-cursors";
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
    in
    "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      sway-contrib.grimshot
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

  # Needed for sway/niri to get a working GL context -- same as vm, but for
  # real reasons here (actual GPU driver setup) rather than working around
  # virtualized graphics.
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true; # 32-bit Steam games need this too

  # NOT carrying over vm's WLR_NO_HARDWARE_CURSORS=1 -- that was a
  # VirtualBox-specific cursor-plane workaround (see DECISIONS.md). Re-add
  # if the real GPU turns out to have the same issue.

  # Hybrid graphics: AMD Cezanne iGPU (amdgpu, drives the internal panel --
  # this is a muxless laptop, the NVIDIA GPU has no display wired to it at
  # all) + NVIDIA RTX 3060 Mobile dGPU. Was falling back to the open-source
  # `nouveau`/NVK stack (confirmed working -- GSP firmware loads, Vulkan
  # via NVK enumerates the card fine -- but nothing selected it for actual
  # use, and NVK's OpenGL path is weak on this GPU generation). Switched to
  # the proprietary driver in PRIME offload mode (not sync -- sync needs a
  # mux to drive the display from the dGPU, which this laptop doesn't
  # have) for real gaming performance -- see DECISIONS.md.
  #
  # `open = true` uses NVIDIA's open-source *kernel* module (not the same
  # thing as nouveau -- this still pulls in NVIDIA's proprietary userspace
  # OpenGL/Vulkan/CUDA libraries). Officially supports Turing and later;
  # this GA106 (Ampere) is well within that range, and NVIDIA has said the
  # open modules are the recommended default for this generation going
  # forward, not just a legacy-compat option.
  #
  # Bus IDs come straight from `lspci` (01:00.0 NVIDIA, 06:00.0 AMD),
  # decimal-converted per NixOS's PCI:bus:slot:function format.
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Powers the dGPU down via ACPI when nothing's using offload -- battery
    # life matters on a laptop, and this is the standard pairing with
    # prime.offload (as opposed to leaving the dGPU powered all the time).
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true; # adds a `nvidia-offload` wrapper
      amdgpuBusId = "PCI:6:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Still needed even under Wayland-only compositors (niri/sway) -- this is
  # what wires up the proprietary driver's GLX/EGL libraries at all, which
  # Xwayland (and anything using XWayland-satellite under niri) needs.
  services.xserver.videoDrivers = [ "nvidia" ];

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

    python3
    python3Packages.pip
    gcc
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

    google-chrome
    discord
    obsidian
    spotify
  ];

  # Real install date (from the fresh /etc/nixos/configuration.nix
  # nixos-generate-config wrote on this machine), not vm's "25.05" --
  # stateVersion tracks each host's own first-install release, not the
  # currently running one.
  system.stateVersion = "26.05";
}
