# Host: legion-laptop (Lenovo Legion 5 17ACH6H, dual-booting Windows). See
# ../../DECISIONS.md for the reasoning behind the choices below.

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
  # Dual-booting Windows on the same hardware clock: Windows assumes the RTC
  # is local time, Linux/NixOS assumes UTC by default -- without this,
  # whichever OS you booted into last "corrects" the clock for its own
  # assumption, so the other OS reads the wrong time until its own next
  # correction. Standard fix on the NixOS side (Windows itself can't easily
  # be told to use UTC).
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
  # Four separate pieces below are all needed together, none optional on
  # their own -- see DECISIONS.md ("SDDM greeter cursor") for why each one
  # exists and what happens without it.
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

  # The greeter's actual visible cursor is drawn by SDDM's own Qt/QML
  # process, a sibling of Weston rather than Weston's own compositor-drawn
  # fallback -- this wrapper only covers the latter, via a generated
  # weston.ini plus XCURSOR_PATH (a bare theme name isn't resolvable
  # outside libXcursor's standard search dirs).
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

  programs.steam = {
    enable = true;

    # Run Steam and its games on the NVIDIA dGPU via PRIME render offload.
    # These values match the nvidia-offload wrapper configured below.
    package = pkgs.steam.override {
      extraEnv = {
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
      };
    };
  };

  programs.niri.enable = true;

  # Force Chrome's web notifications through the standard Linux desktop
  # notification service (org.freedesktop.Notifications), which DMS owns.
  # Without this policy Chrome can fall back to its internal message center,
  # whose blank Wayland toplevels niri treats as ordinary tiled windows.
  environment.etc."opt/chrome/policies/managed/system-notifications.json".text =
    builtins.toJSON { AllowSystemNotifications = true; };

  # Sway was tried as a second session (back after being dropped in
  # 6396fd9) and then torn back down -- decided to just stick with niri.
  # See git history around home/dotfiles/sway for the removed config if
  # this ever comes up again.

  # Session save/restore for niri -- niri itself is deliberately stateless
  # (no layout persistence). Relaunches each window's command and moves it
  # back into place; not a real process restore (a "restored" terminal is
  # empty, a "restored" browser doesn't get its tabs back) -- that's what
  # the tmux-resurrect + mini.sessions changes alongside this one are for.
  # `skip.apps` is empty (nothing currently spawn-at-startup's a window
  # nirinit would double-launch) but kept declared for future use -- see
  # DECISIONS.md for the full history and the skip.apps casing gotcha.
  services.nirinit = {
    enable = true;
    settings.skip.apps = [ ];

    # Real binary name, wherever it differs from the window's Wayland
    # app_id -- nirinit defaults to spawning the app_id itself otherwise,
    # which fails silently when they don't match (confirmed live via
    # `journalctl -u nirinit.service`; see DECISIONS.md). Ghostty points at
    # `ghostty-tmux-attach` (home/santi.nix) rather than plain `ghostty`,
    # so a restored terminal lands inside tmux instead of a bare shell --
    # nirinit only ever passes a single bare executable with no arguments,
    # so the multi-arg `ghostty -e sh -c 'tmux attach || tmux new'` has to
    # live behind a fixed-name wrapper, same reasoning as the wrapper
    # itself documents.
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

  # Needed for niri to get a working GL context at all.
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true; # 32-bit Steam games need this too

  # Hybrid graphics: AMD Cezanne iGPU (amdgpu) + NVIDIA RTX 3060 Mobile
  # dGPU (nvidia). Muxless, but NOT "iGPU drives everything, dGPU has no
  # display wired to it" -- confirmed live (sysfs connector status + `niri
  # msg -j outputs`) that DP-2 and HDMI-A-1 (the two external monitors)
  # are wired directly to the NVIDIA GPU's own KMS output; only eDP-2 (the
  # internal laptop panel) is actually on AMD. See DECISIONS.md. PRIME
  # *offload* (not sync) is still the right call regardless -- sync would
  # mean the dGPU renders the entire desktop full-time for every window,
  # not just the two outputs it already natively drives.
  #
  # Was falling back to the open-source `nouveau`/NVK stack (confirmed
  # working -- GSP firmware loads, Vulkan via NVK enumerates the card fine
  # -- but nothing selected it for actual use, and NVK's OpenGL path is
  # weak on this GPU generation) before switching to the proprietary
  # driver for real gaming performance.
  #
  # `open = true` uses NVIDIA's open-source *kernel* module (not the same
  # thing as nouveau -- still pulls in NVIDIA's proprietary userspace
  # OpenGL/Vulkan/CUDA libraries). Officially supports Turing+; this GA106
  # (Ampere) qualifies, and NVIDIA recommends the open modules as default
  # for this generation now, not just a legacy-compat option.
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

  # Still needed even under a Wayland-only compositor (niri) -- this is what
  # wires up the proprietary driver's GLX/EGL libraries at all, which
  # Xwayland (and xwayland-satellite, niri's Xwayland bridge) needs.
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

  # Compatibility loader for ordinary dynamically linked Linux binaries.
  # OpenSessions installs release binaries through TPM; the default nix-ld
  # library set covers their glibc/libgcc/zlib dependencies, while its bundled
  # lazydiff binary additionally needs libdbus-1.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ dbus ];
  };

  programs.firefox.enable = true;

  # Required by home-manager's services.easyeffects (home/santi.nix) --
  # the daemon needs dconf/gsettings to persist its own state, and the
  # module docs explicitly call out that it won't work correctly without
  # this enabled at the system level.
  programs.dconf.enable = true;

  nixpkgs.config.allowUnfree = true;

  # Everything user-facing (desktop apps, dev tooling, LSPs) lives in
  # home.packages in home/santi.nix instead -- system-level config here
  # stays focused on hardware/drivers/daemons/boot.
  #
  # This one exception stays here: SDDM's pre-login greeter reads
  # XCURSOR_THEME/the weston.ini cursor-theme setting above against the
  # *system* profile (/run/current-system/sw/share/icons) -- home.packages
  # only ever reaches the user profile, which doesn't exist yet at greeter
  # time, so this can't move with everything else.
  environment.systemPackages = [ pkgs.catppuccin-cursors.latteLavender ];

  # Real install date, from the fresh /etc/nixos/configuration.nix
  # nixos-generate-config wrote on this machine -- stateVersion tracks this
  # host's own first-install release, not the currently running one.
  system.stateVersion = "26.05";
}
