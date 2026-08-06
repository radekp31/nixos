{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    devShells = let
      pkgs25_11 = inputs.nixpkgs_deprecated.legacyPackages.${system};
      pkgs_unstable = import inputs.nixpkgs_unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
      import ../modules/devShells {
        inherit pkgs pkgs_unstable system;
        pkgs25_05 = pkgs25_11; # Binds your local directory expectation to your input choice
      };
  };
}
