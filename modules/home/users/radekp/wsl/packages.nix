{
  pkgs,
  ...
}: let
  aztfexport = pkgs.stdenv.mkDerivation {
    pname = "aztfexport";
    version = "0.18.0";

    src = pkgs.fetchurl {
      url = "https://github.com/Azure/aztfexport/releases/download/v0.18.0/aztfexport_v0.18.0_linux_amd64.zip";
      sha256 = "75fb5b695c1f591671c58a3fa88c0efcdde298542335b8ee629705dab3ffbd55";
    };

    nativeBuildInputs = [pkgs.unzip pkgs.autoPatchelfHook];
    buildInputs = [pkgs.stdenv.cc.cc.lib];

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      mkdir -p $out/bin
      install -m755 aztfexport $out/bin/aztfexport
    '';

    meta = with pkgs.lib; {
      description = "A tool to bring existing Azure resources under Terraform's management";
      homepage = "https://github.com/Azure/aztfexport";
      license = licenses.mpl20;
      platforms = ["x86_64-linux"];
    };
  };

  # Look up working commit hashes here: https://www.nixhub.io/packages/azure-cli
  # azcli is for some reason not working from nixpkgs
  nixhubio_azcli =
    import (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/80d901ec0377e19ac3f7bb8c035201e2e098cc97.tar.gz";
      sha256 = "1ik9a5zrzrcd50a055y3n4bljwf9yyd8hg6qj09nlbbjampkjgcv";
    }) {
      system = pkgs.stdenv.targetPlatform.system;
    };
in {
  home.packages = with pkgs; [
    nixos-icons
    alejandra
    nerd-fonts.jetbrains-mono

    (python313.withPackages (ps:
      with ps; [
        openpyxl
        collections-extended
        pandas
        numpy
        pip
        autopep8
        hy
        pathlib2
        requests
        pyyaml
        pydantic
      ]))
    gh
    htop

    bruno
    cheat
    nvd
    nvdtools
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

    sops
    age
    inxi

    tmux

    # Use azure-cli from the pinned commit
    (nixhubio_azcli.azure-cli.withExtensions [
      nixhubio_azcli.azure-cli-extensions.storage-preview
      nixhubio_azcli.azure-cli-extensions.azure-devops
      nixhubio_azcli.azure-cli-extensions.resource-graph
      nixhubio_azcli.azure-cli-extensions.quota
      nixhubio_azcli.azure-cli-extensions.nsp
      nixhubio_azcli.azure-cli-extensions.kusto
      nixhubio_azcli.azure-cli-extensions.graphservices
      nixhubio_azcli.azure-cli-extensions.fzf
      nixhubio_azcli.azure-cli-extensions.dynatrace
    ])

    kubectl
    awscli2
    google-cloud-sdk
    terraformer
    aztfexport
    dig

    fzf
    jq
    git
    docker-compose
    helm
    terraform
    ansible
    powershell
    github-cli

    #Required for Github Copilot
    nodejs_24
    copilot-cli
    opencode

    firefox
  ];
}
