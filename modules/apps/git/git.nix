{ config, pkgs, lib, ...}:

#let

#   vars = import /etc/nixos/modules/apps/git/variables.nix;

#in

{  


   #Enable git
   programs.git = {
       enable = true;
   };

   #Git global configuration
   environment.etc."gitconfig".text = ''
    [user]
      name = "radekp31"
      email = "polaek.31@seznam.cz"
    [credential]
      helper = "store --file /etc/secrets/github-token"
    [init]
      defaultBranch = main
    [safe]
      directory = "/etc/nixos"
   '';

}
