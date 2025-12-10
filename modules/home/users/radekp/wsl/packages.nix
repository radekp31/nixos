{
  pkgs,
  inputs,
  ...
}: let
  nixpkgs2505 = import inputs.nixpkgs25_05 {system = "x86_64-linux";};
in {
  home.packages = with pkgs; [
    (
      nixpkgs2505.azure-cli.withExtensions
      [
        nixpkgs2505.azure-cli-extensions.nsp
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
    #fastfetch # to identify session
    microfetch
    xsel
    docker_28
    inetutils
  ];
}
