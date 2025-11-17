{...}: let
  vars = import ./variables.nix;
in {
  programs.git = {
    enable = true;
  };

  #Git global configuration
  environment.etc."gitconfig".text = ''
    [user]
      name = "${vars.gitHubUser}"
      email = "${vars.gitHubEmail}"
    [credential]
      helper = "store --file ${vars.gitHubTokenFile}"
    [init]
      defaultBranch = "${vars.defaultMain}"
    [safe]
      directory = "${vars.dotfilesDir}"
  '';
}
