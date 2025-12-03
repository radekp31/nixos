{pkgs, ...}: {
  home.packages = with pkgs; [
    (
      azure-cli.withExtensions
      [
        azure-cli-extensions.nsp
        # More extensions
      ]
    )
    # Python with packages (for the CSV processing scripts)
    (python313.withPackages (ps:
      with ps; [
        # More packages
        openpyxl
        collections-extended
        pandas
        numpy
      ]))
    google-cloud-sdk
    fzf
    jq
    #nvim-pkg
    git
    gh # GitHub CLI
    docker-compose
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
    docker_28
  ];
}
