{
  pkgs,
  pkgs_deprecated,
  pkgs_unstable,
  ...
}: let
  # Import custom derivations
  aztfexport = import ./derivations/aztfexport.nix {inherit pkgs;};

  # Import tool definitions
  pythonTools = import ./tools/python.nix {inherit pkgs;};
  devopsTools = import ./tools/devops.nix {inherit pkgs pkgs_unstable aztfexport;};
  azureTools = import ./tools/azure.nix {inherit pkgs_deprecated;};
  nixTools = import ./tools/nix.nix {inherit pkgs;};
  rustTools = import ./tools/rust.nix {inherit pkgs_unstable;};
in {
  default = pkgs.mkShell {
    buildInputs = nixTools.packages;

    shellHook = ''
      export DEVSHELL_NAME="default"
      export NIXPKGS_ALLOW_UNFREE=1
      export SHELL=${pkgs.zsh}/bin/zsh
    '';
  };

  devops = pkgs.mkShell {
    buildInputs =
      pythonTools.packages
      ++ devopsTools.packages
      ++ azureTools.packages;

    shellHook = ''
      export DEVSHELL_NAME="devops"
      export NIXPKGS_ALLOW_UNFREE=1
      export SHELL=${pkgs.zsh}/bin/zsh
    '';
  };

  rust = pkgs.mkShell {
    buildInputs = rustTools.packages;

    # Some crates reach openssl through pkg-config and need the path named.
    PKG_CONFIG_PATH = "${pkgs_unstable.openssl.dev}/lib/pkgconfig";

    shellHook = ''
      export DEVSHELL_NAME="rust"
      export NIXPKGS_ALLOW_UNFREE=1
      export SHELL=${pkgs.zsh}/bin/zsh
      echo "rust dev shell - $(rustc --version)"
    '';
  };
}
