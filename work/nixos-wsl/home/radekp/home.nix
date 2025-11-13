{ config, pkgs, lib,... }:

{

  imports = with pkgs; [
    ./packages.nix
  ];
  home.username = "radekp";
  home.homeDirectory = "/home/radekp";

  programs.git = {
    enable = true;
    userName = "Radek Polasek";
    userEmail = "polasek.31@seznam.cz";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting = {
      enable = true;
      #highlighters = [ "main" "bracket" ];
    };
    autosuggestion = {
      enable = true;
    };
    initContent = ''
      export NIXPKGS_ALLOW_UNFREE=1
      export EDITOR='nvim'
      export VISUAL='nvim'
      export C='/mnt/c'

      fastfetch --config ${pkgs.fastfetch}/share/fastfetch/presets/examples/3.jsonc
    '';
    shellAliases = {
      ll = "ls -lah --color=auto";
      grep = "grep --color=auto";
      vi = "nvim";
      vim = "nvim";
    };
    oh-my-zsh = {
      enable = true;
      theme = "gnzh";
      plugins = [ 
        "copyfile"
        "git"
        "command-not-found"
        "fzf"
        "sudo"
        "azure"
        "aws"
        "gcloud"
        "kubectl"
      ];
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.ssh = {
    enable = true;
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
