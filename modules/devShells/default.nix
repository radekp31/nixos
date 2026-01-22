{
  pkgs,
  pkgs25_05,
  pkgs_unstable,
}: let
  # Import custom derivations
  aztfexport = import ./derivations/aztfexport.nix {inherit pkgs;};

  # Import tool definitions
  pythonTools = import ./tools/python.nix {inherit pkgs;};
  devopsTools = import ./tools/devops.nix {inherit pkgs pkgs_unstable aztfexport;};
  azureTools = import ./tools/azure.nix {inherit pkgs pkgs25_05;};
  nixTools = import ./tools/nix.nix {inherit pkgs;};
in {
  default = pkgs.mkShell {
    buildInputs =
      nixTools.packages
      ++ [pkgs.pre-commit];

    shellHook = ''
      export DEVSHELL_NAME="devops"
      export NIXPKGS_ALLOW_UNFREE=1
      export SHELL=${pkgs.zsh}/bin/zsh
    '';
  };

  devops = pkgs.mkShell {
    buildInputs =
      pythonTools.packages
      ++ devopsTools.packages
      ++ azureTools.packages
      ++ [pkgs.pre-commit];

    shellHook = ''
      export DEVSHELL_NAME="devops"
      export NIXPKGS_ALLOW_UNFREE=1
      export SHELL=${pkgs.zsh}/bin/zsh

      # Install pre-commit hooks from .pre-commit-config.yaml
      if [ -f .pre-commit-config.yaml ]; then
        pre-commit install --install-hooks
      fi

    '';
  };
}
