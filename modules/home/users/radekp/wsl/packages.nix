{pkgs, ...}: {
  home.packages = with pkgs; [
    # Python with packages (for the CSV processing scripts)
    (python313.withPackages (ps:
      with ps; [
        # More packages
        openpyxl
        collections-extended
        pandas
        numpy
      ]))
    fzf
    jq
    git
    gh # GitHub CLI
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
}
