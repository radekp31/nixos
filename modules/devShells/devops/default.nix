{
  pkgs,
  pre-commit-hooks,
  system,
  hooks,
  pythonTools,
  devopsTools,
  azureTools,
}:
pkgs.mkShell {
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
}
