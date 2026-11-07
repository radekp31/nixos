{
  description = "NixOS config.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs_deprecated.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs_unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Revision with azure-cli 2.85.0. Version 2.86.0 fails with delegated_user_tid. Change the rev to move the pin.
    nixpkgs_azcli_pin.url = "github:NixOS/nixpkgs/546500056776c6cd4ed763252295bf5b71a18e07";

    flake-parts.url = "github:hercules-ci/flake-parts";

    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Supplies pkgs_unstable.rust-bin for the rust devShell. It follows
    # nixpkgs_unstable, so it adds one lock node and no second nixpkgs.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs_unstable";
    };

    # Declarative disk partitioning. nixos-desktop imports it for the
    # format script only; see hosts/nixos-desktop/disk-config.nix.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # greetd greeter. modules/system/apps/desktop/sysc-greet builds it from
    # this source and takes gslapper from this input. The upstream NixOS
    # module is not used. The tag pins a release; flake.lock pins the commit.
    sysc-greet = {
      url = "github:Nomadcxx/sysc-greet/v1.3.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {
    flake-parts,
    systems,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import systems;

      imports = [
        ./parts/formatting.nix
        ./parts/shells.nix
        ./parts/hosts.nix
        ./parts/disks.nix
      ];
    };
}
