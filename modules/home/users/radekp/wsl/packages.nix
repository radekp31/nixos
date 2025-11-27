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
        # No additional packages needed! All scripts use only standard library:
        # - csv (built-in)
        # - subprocess (built-in)
        # - json (built-in)
        # - sys (built-in)
        # - pathlib (built-in)
      ]))
    fzf
    jq
    #nvim-pkg
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
