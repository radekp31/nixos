{
  config,
  osConfig,
  ...
}: {
  imports = [
    ./packages.nix
    ../../../shells/zsh
    ../../../colorschemes/catppuccin
    ../../../apps/tmux
  ];
  home.username = osConfig.my.user.name;
  home.homeDirectory = osConfig.my.user.home;

  programs.git = {
    enable = true;
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
        name = osConfig.my.user.fullName;
        email = osConfig.my.user.workEmail;
      };
      init.defaultBranch = "main";
      safe.directory = "/etc/nixos";
      pull.rebase = true;
    };
  };

  xdg.configFile."git/user-dynatrace-bitbucket.gitconfig".text = ''
    [user]
      name = ${osConfig.my.user.fullName}
      email = ${osConfig.my.user.workEmail}
  '';

  xdg.configFile."git/user-dynatrace-github.gitconfig".text = ''
    [user]
      name = ${osConfig.my.user.fullName}
      email = ${osConfig.my.user.workEmail}

    [url "ssh://git@github.com/Dynatrace-Internal/rnd-ai-knowledgebase"]
      insteadOf = https://github.com/Dynatrace-Internal/rnd-ai-knowledgebase
  '';

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
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
    enable = false;
  };

  xdg.configFile."wezterm/wezterm.lua".source = ../../../apps/wezterm/wezterm.lua;

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
