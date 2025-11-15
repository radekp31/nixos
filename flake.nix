{
  description = "NixOS config flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
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
      url = "github:radekp31/kickstart-nix.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";
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
    treefmt-nix,
    systems,
    ...
  } @ inputs: let
    inherit (self) outputs;
    system = "x86_64-linux";

    # Treefmt-nix
    # Small tool to iterate over each systems
    eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});

    # Eval the treefmt modules from ./treefmt.nix
    treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./modules/system/apps/treefmt/treefmt.nix);
  in {
    nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem {
      #system = "x86_64-linux";
      system = system;
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/nixos-desktop/configuration.nix
        ./modules/system/secrets/sops.nix
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
        ./hosts/server/generic/configuration.nix
        ./modules/system/secrets/sops.nix
        #sops-nix.nixosModules.sops
      ];
    };

    nixosConfigurations.web-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/server/generic/configuration.nix
        ./modules/system/secrets/sops.nix
        ./modules/system/server/webserver/configuration.nix
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
        ./modules/system/secrets/sops.nix
      ];
    };

    nixosConfigurations."dt-wsl-nix" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-wsl.nixosModules.wsl
        ./hosts/nixos-wsl/configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.radekp = import ./home/radekp/home.nix; #this location needs fixing
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
          ./modules/home/users/radekp.nix # This needs to be change to HM as module
          #sops-nix.homeManagerModules.sops
        ];
      };
    };

    # Formatter

    # for `nix fmt`
    formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
    # for `nix flake check`
    checks = eachSystem (pkgs: {
      formatting = treefmtEval.${pkgs.system}.config.build.check self;
    });

    # Create a dev shell
    # devShell = nixpkgs.mkShell {
    #   buildInputs = [ ... ];
    # };
  };
}
