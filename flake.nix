{
  description = "NixOS config flake.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";

    alejandra.url = "github:kamadorueda/alejandra";

    #nixos-anywhere inputs
    #inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; #seems incorrect, needs testing

    disko.url = "github:nix-community/disko";

    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  };

  outputs = { self, nixpkgs, alejandra, home-manager, disko, ... }@inputs:

    let

      inherit (self) outputs;
      system = "x86_64-linux";

    in

    {

      nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem {
        #system = "x86_64-linux";
        system = system;
        modules = [
          ./configurations/nixos-desktop/configuration.nix

        ];
      };


      nixosConfigurations.generic-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configurations/server/generic/configuration.nix
        ];
      };

      #Remote deployments with nixos-anywhere
      #Run with:
      #nixos-anywhere --flake .#generic --generate-hardware-config nixos-generate-config ./hardware-configuration.nix root@IP -i <ssh-key-path>

      nixosConfigurations.deployment-generic-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./deployments/server/generic/configuration.nix
          ./deployments/server/generic/hardware-configuration.nix
        ];
      };

      homeConfigurations = {
        "radekp" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./home-manager/personal/radekp.nix ];
        };
      };

      # Formatter

      packages.${system}.alejandra = alejandra.packages.${system}.default;

      formatter.${system} = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      # devShell = nixpkgs.mkShell {
      #   buildInputs = [ ... ];
      # };
    };
}

