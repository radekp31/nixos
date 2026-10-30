# claude-code from the nixpkgs_unstable input. The release input runs weeks
# behind upstream.
#
# The overlay replaces one attribute. No derivation in nixpkgs depends on
# claude-code, so no other package hash moves.
#
# allowUnfree is mandatory. claude-code carries an unfree license, so a plain
# inputs.nixpkgs_unstable.legacyPackages read throws.
#
# The overlay reaches the Home Manager package lists too, because every host
# sets home-manager.useGlobalPkgs = true in parts/hosts.nix.
{inputs, ...}: {
  nixpkgs.overlays = [
    (_final: prev: {
      claude-code =
        (import inputs.nixpkgs_unstable {
          inherit (prev) system;
          config.allowUnfree = true;
        })
        .claude-code;
    })
  ];
}
