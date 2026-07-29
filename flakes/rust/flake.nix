{
  description = "Rust dev shell for codesearch tool";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer"];
	  targets = [ "wasm32-unknown-unknown" ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
	    wasm-pack
	    binaryen
	    
            rustToolchain

            # build tooling
            pkg-config
            openssl

            # useful for testing the actual CLI tools this project wraps
            ripgrep
            fzf

            # handy extras for a web+rust project
            cargo-watch
            cargo-edit
            nodejs_22   # only if you end up wanting a JS build step for the frontend
          ];

          # some crates (e.g. openssl-sys via tokio-tungstenite tls features) need this
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";

          shellHook = ''
            echo "codesearch dev shell — rustc $(rustc --version)"
          '';
        };
      });
}
