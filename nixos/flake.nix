{
  description = "Santi's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    # Declarative Spotify theming (Catppuccin, via spicetify) -- wraps the
    # actual Spotify package with the theme baked in at build time, instead
    # of the traditional spicetify-cli's imperative "patch the installed
    # app, re-run after every update" flow. Same maintainer (gerg-l) as
    # nixpkgs' own spicetify-cli package, not an orphaned side project.
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop shell (bar, control center, launcher, lock screen) replacing
    # waybar/fuzzel/swaylock/swayidle -- see home/santi.nix's
    # `programs.dank-material-shell` block and niri/config.kdl for the
    # rest of the wiring. Pinned to the "stable" branch (its own release
    # channel, not a git tag) rather than master, on the project's own
    # recommendation.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Session save/restore for niri (see hosts/legion-laptop/configuration.nix's
    # `services.nirinit` for the actual config, DECISIONS.md for why) --
    # relaunches windows back into their tracked workspace/output/size on
    # login, periodically re-saves in the background. Ships its own
    # `nixosModules.nirinit` (NixOS-level, not home-manager -- it wires up
    # `systemd.user.services.nirinit` directly).
    nirinit = {
      url = "github:amaanq/nirinit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Sticky floating windows for niri (no native concept of this --
    # niri-wm/niri#678). Daemon watches floating windows and keeps sticky
    # ones visible across every workspace; see home/santi.nix for the
    # package wiring and niri/config.kdl for the spawn + toggle keybind.
    # Plain package flake (`pkgs.callPackage ./package.nix {}`), not a
    # NixOS/home-manager module.
    niri-float-sticky = {
      url = "github:probeldev/niri-float-sticky";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, catppuccin, spicetify-nix, dms, nirinit, niri-float-sticky, ... }@inputs: {
    nixosConfigurations = {
      # The real laptop (Lenovo Legion 5 17ACH6H). See
      # hosts/legion-laptop/configuration.nix for why this is
      # "legion-laptop" (hyphen) rather than the invalid "legion_laptop"
      # the initial install used, or the live "legionlaptop" it currently
      # resolves to at runtime as a result.
      legion-laptop = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/legion-laptop/configuration.nix
          catppuccin.nixosModules.catppuccin
          nirinit.nixosModules.nirinit
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.santi = import ./home/santi.nix;
            home-manager.sharedModules = [
              catppuccin.homeModules.catppuccin
              spicetify-nix.homeManagerModules.spicetify
              dms.homeModules.dank-material-shell
            ];
            # santi.nix needs `inputs.spicetify-nix.legacyPackages` to reach
            # spicetify-nix's theme set -- specialArgs above only reaches
            # NixOS-level modules, home-manager's user config needs its own
            # extraSpecialArgs to get the same `inputs` binding.
            home-manager.extraSpecialArgs = { inherit inputs; };
            # Pre-existing, non-symlinked files at a path home-manager wants
            # to manage (leftover app defaults, or artifacts from switching
            # xdg.configFile between whole-directory and per-file sources,
            # like the waybar/fuzzel/swaylock restructuring) get backed up
            # with this suffix instead of blocking activation.
            home-manager.backupFileExtension = "backup";
          }
        ];
      };

      # Template for a second NixOS machine sharing the same home/santi.nix
      # desktop -- see hosts/new-machine/configuration.nix for the setup
      # steps this needs first (real hostname, that machine's own
      # hardware-configuration.nix, GPU-specific review). Left commented out
      # rather than wired up live: with no hardware-configuration.nix yet,
      # evaluating this block would fail every `nix flake check` and
      # `nixos-rebuild`/`home-manager switch` run on legion-laptop too, since
      # flake outputs are checked together. Uncomment once
      # hosts/new-machine/ has a real hardware-configuration.nix (and ideally
      # rename "new-machine" to the real hostname, here and as the directory
      # name).
      #
      # new-machine = nixpkgs.lib.nixosSystem {
      #   specialArgs = { inherit inputs; };
      #   modules = [
      #     ./hosts/new-machine/configuration.nix
      #     catppuccin.nixosModules.catppuccin
      #     nirinit.nixosModules.nirinit
      #     home-manager.nixosModules.home-manager
      #     {
      #       home-manager.useGlobalPkgs = true;
      #       home-manager.useUserPackages = true;
      #       home-manager.users.santi = import ./home/santi.nix;
      #       home-manager.sharedModules = [
      #         catppuccin.homeModules.catppuccin
      #         spicetify-nix.homeManagerModules.spicetify
      #         dms.homeModules.dank-material-shell
      #       ];
      #       home-manager.extraSpecialArgs = { inherit inputs; };
      #       home-manager.backupFileExtension = "backup";
      #     }
      #   ];
      # };
    };

    # Standalone home-manager entry point for the portable subset of
    # home/santi.nix (shell, git, neovim, tmux, dev CLI tooling -- see
    # home/core.nix) for machines that aren't running this flake's NixOS
    # config at all: `home-manager switch --flake ~/dotfiles/nixos#santi`.
    # Deliberately does NOT pull in home/santi.nix itself -- that also
    # declares this laptop's whole niri/DankMaterialShell desktop, GPU
    # offload wrappers, etc, none of which make sense on an arbitrary other
    # machine.
    homeConfigurations = {
      santi = home-manager.lib.homeManagerConfiguration {
        # Hardcoded rather than derived from the running system, since flake
        # evaluation has to stay pure -- override this if the other machine
        # isn't x86_64 (e.g. "aarch64-linux" for an ARM machine).
        #
        # `allowUnfree` has to be set here explicitly (unlike the NixOS
        # target, where hosts/legion-laptop/configuration.nix's top-level
        # `nixpkgs.config.allowUnfree` flows down to home-manager via
        # `useGlobalPkgs`) -- core.nix installs claude-code, which is
        # unfree-licensed; plain `nixpkgs.legacyPackages` refuses to
        # evaluate it without this.
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        extraSpecialArgs = { inherit inputs; };
        modules = [
          catppuccin.homeModules.catppuccin
          ./home/core.nix
        ];
      };
    };
  };
}
