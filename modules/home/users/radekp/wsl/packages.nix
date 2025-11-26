{pkgs, ...}: {
  home.packages = with pkgs; [
    (
      azure-cli.withExtensions
      [
        azure-cli-extensions.nsp
        # More extensions
      ]
    )
    fzf
    jq
    nvim-pkg
    git
    gh # GitHub CLI
    docker-compose
    kubectl
    helm
    awscli2
    google-cloud-sdk
    terraform
    ansible
    htop
    curl
    wget
    netcat
    ripgrep-all
    fd
    bat
    kubectl
    tree
    fastfetch # to identify session
    xsel
    awscli2
  ];
}
