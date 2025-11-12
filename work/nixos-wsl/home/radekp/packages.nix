{config, lib, pkgs, ...}:
{

  home.packages = with pkgs; [

  #azure-cli
  #azure-cli-extensions.nsp
  (azure-cli.withExtensions [
     azure-cli-extensions.nsp]
  )
  fzf
  jq
  nvim-pkg
  
  ];
}

