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
  };

  outputs = { self, nixpkgs, home-manager, catppuccin, spicetify-nix, ... }@inputs: {
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
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.santi = import ./home/santi.nix;
            home-manager.sharedModules = [
              catppuccin.homeModules.catppuccin
              spicetify-nix.homeManagerModules.spicetify
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
    };
  };
}
