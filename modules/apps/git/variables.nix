#/modules/apps/git/variables.nix
{
  defaultMain = "main";
  dotfilesDir = "/etc/nixos";
  gitHubRepo = "git@github.com:radekp31/nixos.git"; # Replace with your repo
  gitHubUser = "radekp31";
  gitHubEmail = "polaek.31@seznam.cz";
  gitHubTokenFile = "/etc/secrets/github-token"; # Define path for your GitHub token
}
