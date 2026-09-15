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
}
