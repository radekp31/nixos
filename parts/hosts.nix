# One helper builds every host.
#
# A host declares only what makes it different: its configuration file, its
# Home Manager profile, and any module that must load before the host file.
# Everything the hosts share lives in mkHost once.
{inputs, ...}: let
  system = "x86_64-linux";

  mkHost = {
    configuration,
    homeProfile,
    extraModules ? [],
  }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {inherit inputs;};
      modules =
        extraModules
        ++ [
          configuration
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.radekp.imports = [
              homeProfile
              ../patches/opencode-stub.nix
            ];
          }
        ];
    };
in {
  flake.nixosConfigurations = {
    nixos-desktop = mkHost {
      configuration = ../hosts/nixos-desktop/configuration.nix;
      homeProfile = ../modules/home/users/radekp/desktop;
    };

    # The attribute name and the host directory differ on purpose.
    "dt-wsl-nix" = mkHost {
      configuration = ../hosts/nixos-wsl/configuration.nix;
      homeProfile = ../modules/home/users/radekp/wsl;
      extraModules = [inputs.nixos-wsl.nixosModules.wsl];
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
