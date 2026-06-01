{inputs, ...}: let
  system = "x86_64-linux";
in {
  flake.nixosConfigurations = {
    nixos-desktop = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [
        ../hosts/nixos-desktop/configuration.nix
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.radekp = {
            imports = [
              (import ../modules/home/users/radekp/desktop)
              ../patches/opencode-stub.nix
            ];
          };
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = {inherit inputs;};
        }
      ];
    };

    "dt-wsl-nix" = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules = [
        inputs.nixos-wsl.nixosModules.wsl
        ../hosts/nixos-wsl/configuration.nix
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.radekp = {
            imports = [
              (import ../modules/home/users/radekp/wsl)
              ../patches/opencode-stub.nix
            ];
          };
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = {inherit inputs;};
        }
      ];
    };
    # Uncomment when sops is fixed
    #nixosConfigurations.generic-server = nixpkgs.lib.nixosSystem {
    #  system = "x86_64-linux";
    #  specialArgs = {inherit inputs;};
    #  modules = [
    #    ../hosts/server/generic/configuration.nix
    #    #../modules/system/secrets/sops
    #  ];
    #};

    #nixosConfigurations.web-server = nixpkgs.lib.nixosSystem {
    #  system = "x86_64-linux";
    #  specialArgs = {inherit inputs;};
    #  modules = [
    #    ../hosts/server/generic/configuration.nix
    #    ../modules/system/secrets/sops
    #    ../modules/system/server/webserver
    #    #sops-nix.nixosModules.sops
    #  ];
    #};

    #nixosConfigurations.deployment-generic-server = nixpkgs.lib.nixosSystem {
    #  system = "x86_64-linux";
    #  specialArgs = {inherit inputs;};
    #  modules = [
    #    disko.nixosModules.disko
    #    ../hosts/deployments/server/generic/configuration.nix
    #    ../hosts/deployments/server/generic/disk-config.nix
    #    #../modules/system/secrets/sops
    #  ];
    #};
  };
}
