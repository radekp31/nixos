{...}: {
  imports = [
    ./packages.nix
    ../../../shells/zsh
    #../../../shells/bash
  ];
  home.username = "radekp";
  home.homeDirectory = "/home/radekp";

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Radek Polasek";
        email = "polasek.31@seznam.cz";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
    #extraConfig = {
    #  init.defaultBranch = "main";
    #  pull.rebase = true;
    #};
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.docker-cli = {
    enable = true;
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
}
