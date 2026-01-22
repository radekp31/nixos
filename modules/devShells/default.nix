{
  pkgs,
  pkgs25_05,
  pkgs_unstable,
  pre-commit-hooks,
  system
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

      ${pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          treefmt.enable = true;
          detect-secrets.enable = true;
          truffleHog.enable = true;
        };
      }}
    '';
  };
}
