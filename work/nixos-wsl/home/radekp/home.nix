{ config, pkgs, lib,... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "radekp";
  home.homeDirectory = "/home/radekp";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ll = "ls -lah --color=auto";
      grep = "grep --color=auto";
    };
    oh-my-zsh = {
      enable = true;
      theme = "gnzh";
      plugins = [ 
        "git"
        "sudo"
      ];
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  #programs.enable = true;
}
