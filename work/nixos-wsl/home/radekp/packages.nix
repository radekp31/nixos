{config, lib, pkgs, ...}:
{

  home.packages = with pkgs; [

  (azure-cli.withExtensions
    [
     azure-cli-extensions.nsp
     # More extensions
    ]
  )
  fzf
  jq
  nvim-pkg
  git
  gh  # GitHub CLI
  docker-compose
  kubectl
  k9s  # K8s TUI
  helm
  awscli2
  google-cloud-sdk
  terraform
  ansible
  htop
  curl
  wget
  netcat
  ripgrep
  fd
  bat
  kubectl

  fastfetch # to identify session
  
  ];
}

