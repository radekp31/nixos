{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: {
    devShells = let
      # Name each pin after its purpose, never after a release number.
      # A release number goes stale the moment the input moves.
      pkgs_deprecated = inputs.nixpkgs_deprecated.legacyPackages.${system};
      # rust-overlay only ADDS rust-bin. It replaces nothing the other shells
      # read, and the devops derivation hash proves that.
      pkgs_unstable = import inputs.nixpkgs_unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [(import inputs.rust-overlay)];
      };
    in
      import ../modules/devShells {
        inherit pkgs pkgs_deprecated pkgs_unstable system;
      };
  };
}
