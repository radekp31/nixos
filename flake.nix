{
  description = "NixOS config flake.";

  inputs = {
    #nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kickstart-nix-nvim = {
      url="github:radekp31/kickstart-nix.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    alejandra,
    home-manager,
    disko,
    sops-nix,
    nixos-wsl,
    kickstart-nix-nvim,
    ...
  } @ inputs: let
    inherit (self) outputs;
    system = "x86_64-linux";
  in {
    nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem {
      #system = "x86_64-linux";
      system = system;
      specialArgs = {inherit inputs;};
      modules = [
        ./configurations/nixos-desktop/configuration.nix
        ./modules/secrets/sops.nix
        #sops-nix.nixosModules.sops
        {
          environment.systemPackages = [alejandra.defaultPackage.${system}];
        }
      ];
    };

    nixosConfigurations.generic-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        ./configurations/server/generic/configuration.nix
        ./modules/secrets/sops.nix
        #sops-nix.nixosModules.sops
      ];
    };

    nixosConfigurations.web-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        ./configurations/server/generic/configuration.nix
        ./modules/secrets/sops.nix
        ./modules/server/webserver/configuration.nix
        sops-nix.nixosModules.sops
      ];
    };

    #Remote deployments with nixos-anywhere
    #Run with:
    #nixos-anywhere --flake .#generic --generate-hardware-config nixos-generate-config ./hardware-configuration.nix root@IP -i <ssh-key-path>

    nixosConfigurations.deployment-generic-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        disko.nixosModules.disko
        ./deployments/server/generic/configuration.nix
        ./deployments/server/generic/hardware-configuration.nix
        ./modules/secrets/sops.nix
      ];
    };

    nixosConfigurations."dt-wsl-nix" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
           nixos-wsl.nixosModules.wsl
          ./work/nixos-wsl/system/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.radekp = import ./work/nixos-wsl/home/radekp/home.nix;
            # Optionally, pass extra arguments to home-manager modules
            # home-manager.extraSpecialArgs = { };
          }
	  {
            nixpkgs.overlays = [
              kickstart-nix-nvim.overlays.default
            ];
          }
        ];
    };

    homeConfigurations = {
      "radekp" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/personal/radekp.nix
          #sops-nix.homeManagerModules.sops
        ];
      };
    };

    # Formatter

    #packages.${system}.alejandra = alejandra.packages.${system}.default;
    #
    formatter.${system} = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

    # devShell = nixpkgs.mkShell {
    #   buildInputs = [ ... ];
    # };
  };
}


