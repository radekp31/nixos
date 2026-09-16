# The toolchain for the rust devShell. It came from flakes/rust/flake.nix,
# which drifted because no job updated its own lock.
{pkgs_unstable}: let
  # rust-src and rust-analyzer ship with the toolchain, so an editor needs no
  # second install. wasm32 is a compile target, not a package.
  rustToolchain = pkgs_unstable.rust-bin.stable.latest.default.override {
    extensions = ["rust-src" "rust-analyzer"];
    targets = ["wasm32-unknown-unknown"];
  };
in {
  inherit rustToolchain;

  packages = with pkgs_unstable; [
    rustToolchain

    # wasm output
    wasm-pack
    binaryen

    # build tooling
    pkg-config
    openssl

    # the CLI tools this project wraps
    ripgrep
    fzf

    # web and rust extras
    cargo-watch
    cargo-edit
    nodejs_22
  ];
}
