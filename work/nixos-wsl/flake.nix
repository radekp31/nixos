{
  description = "Nixos-WSL system";

  inputs = {
    
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-wsl,home-manager, ... }:
  
  let
    system = "x86_64-linux";
  in
  
  {
    nixosConfigurations."dt-wsl-nix" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
	   nixos-wsl.nixosModules.wsl 
          ./system/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.radekp = import ./home/radekp/home.nix;
            # Optionally, pass extra arguments to home-manager modules
            # home-manager.extraSpecialArgs = { };
          }
        ];
    };
  };

}
