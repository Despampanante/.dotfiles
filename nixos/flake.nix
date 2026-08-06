{
  description = "Santi's NixOS config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";
  };

  outputs = { self, nixpkgs, home-manager, catppuccin, ... }@inputs: {
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
            home-manager.sharedModules = [ catppuccin.homeModules.catppuccin ];
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
