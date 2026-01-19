{
  pkgs,
  pkgs_unstable,
  aztfexport,
}: {
  packages = with pkgs; [
    kubectl
    awscli2
    google-cloud-sdk
    terraformer
    aztfexport
    dig
    fzf
    jq
    git
    gh
    docker-compose
    helm
    pkgs_unstable.terraform
    ansible
    htop
    curl
    wget
    netcat
    ripgrep-all
    fd
    bat
    tree
    microfetch
    xsel
    docker_28
    inetutils
  ];

  hooks = {
    yamllint.enable = true;
  };
}
