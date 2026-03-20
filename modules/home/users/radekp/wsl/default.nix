{config, ...}: {
  imports = [
    ./packages.nix
    ../../../shells/zsh
    ../../../colorschemes/catppuccin
  ];
  home.username = "radekp";
  home.homeDirectory = "/home/radekp";

  programs.git = {
    enable = true;
    #includes = [
    #  {
    #    condition = "gitdir:/mnt/c/workspaces/dt_workspaces/**";
    #    #path = "${config.xdg.configHome}/git/user-dynatrace.gitconfig";
    #    path = "${config.xdg.configHome}/git/bitbucket.lab.dynatrace.org.gitconfig";
    #  }
    #  {
    #    condition = "gitdir:/mnt/c/workspaces/dt_github_workspaces/**";
    #    #path = "${config.xdg.configHome}/git/user-dynatrace.gitconfig";
    #    path = "${config.xdg.configHome}/git/github-dynatrace.gitconfig";
    #  }
    #];
    includes = [
      {
        condition = "gitdir:/mnt/c/workspaces/dt_workspaces/**";
        path = "${config.xdg.configHome}/git/user-dynatrace-bitbucket.gitconfig";
      }
      {
        condition = "gitdir:/mnt/c/workspaces/dt_github_workspaces/**";
        path = "${config.xdg.configHome}/git/user-dynatrace-github.gitconfig";
      }
    ];
    settings = {
      user = {
        name = "Radek Polasek";
        email = "polasek.31@seznam.cz";
      };
      init.defaultBranch = "main";
      safe.directory = "/etc/nixos";
      pull.rebase = true;
    };
  };

  #xdg.configFile."git/user-dynatrace.gitconfig".text = ''
  #  [user]
  #    name = Radek Polasek (Dynatrace)
  #    email = radek.polasek@dynatrace.com
  #'';

  #xdg.configFile."git/user-personal.gitconfig".text = ''
  #  [user]
  #    name = Radek Polasek
  #    email = polasek.31@seznam.cz
  #'';
  xdg.configFile."git/user-dynatrace-bitbucket.gitconfig".text = ''
    [user]
      name = Radek Polasek (Dynatrace)
      email = radek.polasek@dynatrace.com
  '';

  xdg.configFile."git/user-dynatrace-github.gitconfig".text = ''
    [user]
      name = Radek Polasek (Dynatrace)
      email = radek.polasek@dynatrace.com
  '';

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      # Personal GitHub account
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github_personal";
      };
      # Dynatrace GitHub account
      "github-dynatrace" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github_dynatrace";
      };
      # Dynatrace Bitbucket account
      "bitbucket.lab.dynatrace.org" = {
        hostname = "bitbucket.lab.dynatrace.org";
        user = "git";
        identityFile = "~/.ssh/dt_bitbucket";
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
