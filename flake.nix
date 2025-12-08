{
  description = "NixOS config flake.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Azure CLI on 25.11 is fooked - revisit later to check if it works again
    # Use az login --tenant <TENANT_ID> --use-device-code
    nixpkgs25_05.url = "github:NixOS/nixpkgs/nixos-25.05";

    #home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixos-wsl = {
      #url = "github:nix-community/NixOS-WSL";
      url = "github:nix-community/NixOS-WSL/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kickstart-nix-nvim = {
      url = "github:radekp31/kickstart-nix.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";

    # Add nixvim here
    nixvim = {
      #url = "github:nix-community/nixvim/nixos-25.05";
      url = "github:nix-community/nixvim/nixos-25.11";
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
    treefmt-nix,
    systems,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    # Treefmt-nix
    # Small tool to iterate over each systems
    eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});

    # Eval the treefmt modules from ./treefmt.nix
    treefmtEval = eachSystem (
      pkgs:
        treefmt-nix.lib.evalModule pkgs {
          imports = [./treefmt.nix];
          programs.alejandra.package = alejandra.defaultPackage.${pkgs.system};
        }
    );
  in {
    nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem {
      #system = "x86_64-linux";
      system = system;
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/nixos-desktop/configuration.nix
        ./modules/system/secrets/sops
        #sops-nix.nixosModules.sops
        {
          environment.systemPackages = [alejandra.defaultPackage.${system}];
        }
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.radekp = import ./modules/home/users/radekp/desktop;
          # Optionally, pass extra arguments to home-manager modules
          # home-manager.extraSpecialArgs = { };
        }
      ];
    };

    nixosConfigurations.generic-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/server/generic/configuration.nix
        ./modules/system/secrets/sops
        #sops-nix.nixosModules.sops
      ];
    };

    nixosConfigurations.web-server = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/server/generic/configuration.nix
        ./modules/system/secrets/sops
        ./modules/system/server/webserver
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
        ./hosts/deployments/server/generic/configuration.nix
        ./hosts/deployments/server/generic/disk-config.nix
        ./modules/system/secrets/sops
      ];
    };

    nixosConfigurations."dt-wsl-nix" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        nixos-wsl.nixosModules.wsl
        ./hosts/nixos-wsl/configuration.nix
        home-manager.nixosModules.home-manager
        #{
        #  nixpkgs.overlays = [
        #    kickstart-nix-nvim.overlays.default
        #  ];
        #}
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.radekp = import ./modules/home/users/radekp/wsl;
          # Optionally, pass extra arguments to home-manager modules
          home-manager.extraSpecialArgs = {inherit inputs;};
        }
      ];
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
