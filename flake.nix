{
  description = "NixOS config flake.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";

    alejandra.url = "github:kamadorueda/alejandra";

    disko.url = "github:nix-community/disko";

    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    sops-nix.url = "github:Mic92/sops-nix";

  };

  #outputs = { self, nixpkgs, alejandra, home-manager, disko, sops-nix, ... }@inputs: #It should not be neccessary to include all input names in outputs = {}, while @inputs is defined. Using specialArgs = {inherit inputs;}; in configurations should be sufficient
  outputs = { self, nixpkgs, home-manager, alejandra, ... }@inputs: #It should not be neccessary to include all input names in outputs = {}, while @inputs is defined. Using specialArgs = {inherit inputs;}; in configurations should be sufficient

    let

      inherit (self) outputs;
      system = "x86_64-linux";

    in

    {

      nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem {
        #system = "x86_64-linux";
        system = system;
        specialArgs = { inherit inputs; };
        modules = [
          ./configurations/nixos-desktop/configuration.nix
          ./modules/secrets/sops.nix
          #sops-nix.nixosModules.sops
        ];
      };


      nixosConfigurations.generic-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configurations/server/generic/configuration.nix
          #sops-nix.nixosModules.sops
        ];
      };

      #Remote deployments with nixos-anywhere
      #Run with:
      #nixos-anywhere --flake .#generic --generate-hardware-config nixos-generate-config ./hardware-configuration.nix root@IP -i <ssh-key-path>

      nixosConfigurations.deployment-generic-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          #disko.nixosModules.disko
          ./deployments/server/generic/configuration.nix
          ./deployments/server/generic/hardware-configuration.nix
        ];
      };

      homeConfigurations = {
        "radekp" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home-manager/personal/radekp.nix
            #sops-nix.homeManagerModules.sops
          ];
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

