{
  pkgs,
  pkgs25_05,
  pkgs_unstable,
  pre-commit-hooks,
  system,
}: let
  # Import custom derivations
  aztfexport = import ./derivations/aztfexport.nix {inherit pkgs;};

  # Import tool definitions
  pythonTools = import ./tools/python.nix {inherit pkgs;};
  devopsTools = import ./tools/devops.nix {inherit pkgs pkgs_unstable aztfexport;};
  azureTools = import ./tools/azure.nix {inherit pkgs pkgs25_05;};
  nixTools = import ./tools/nix.nix {inherit pkgs;};
  hooks = import ./tools/hooks.nix;
in {
  default = pkgs.mkShell {
    buildInputs = nixTools.packages;
    shellHook = ''
      ${pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = hooks.nix;
      }}
    '';
  };

  devops = pkgs.mkShell {
    buildInputs =
      pythonTools.packages
      ++ devopsTools.packages
      ++ azureTools.packages;

    shellHook = ''
      export DEVSHELL_NAME="devops"
      export NIXPKGS_ALLOW_UNFREE="1"
      export SHELL=${pkgs.zsh}/bin/zsh

      ${pre-commit-hooks.lib.${system}.run {
        src = ./.;
        hooks = hooks.python // hooks.devops // azureTools.hooks;
      }}

      exec ${pkgs.zsh}/bin/zsh
    '';
  };
}
