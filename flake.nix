{
  description = "NixOS config flake.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";

    alejandra.url = "github:kamadorueda/alejandra";

  };

  outputs = { self, nixpkgs, alejandra, ... }@inputs:

    let

      system = "x86_64-linux";

    in

    {

      nixosConfigurations.nixos-desktop = nixpkgs.lib.nixosSystem {
        #system = "x86_64-linux";
        system = system;
        modules = [
          # Import the previous configuration.nix we used,
          # so the old configuration file still takes effect
          ./configuration.nix

        ];
      };

      # Formatter

      packages.${system}.alejandra = alejandra.packages.${system}.default;

      formatter.${system} = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      # Optionally, add DevShell configurations if needed
      # devShell = nixpkgs.mkShell {
      #   buildInputs = [ ... ];
      # };


    };
}

