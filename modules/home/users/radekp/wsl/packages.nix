{
  pkgs,
  inputs,
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

  # Define python-tss-sdk from GitHub
  python-tss-sdk = pkgs.python313Packages.buildPythonPackage {
    pname = "python-tss-sdk";
    version = "git-2025-01-01"; # or any label you like

    src = pkgs.fetchFromGitHub {
      owner = "DelineaXPM";
      repo = "python-tss-sdk";
      # You MUST pin to a commit or tag; use `nix-prefetch-git` to get these:
      rev = "f483f8148447a9da7bbca3f973f3280560f81e91";
      sha256 = "1i36qwh9z6hh9b3s02qqs0f0ln3a462slasr9palgsjd5nmvwhxd";
    };

    # If the project uses pyproject.toml, you may need:
    # format = "pyproject";
    # nativeBuildInputs = [ pkgs.python313Packages.setuptools pkgs.python313Packages.wheel ];

    # This tells Nix to use the PEP 517/518 pyproject build backend
    format = "pyproject";

    # Build-system: [ "setuptools" ]
    nativeBuildInputs = with pkgs.python313Packages; [
      flit-core
    ];

    # If tests fail or pull in huge deps:
    doCheck = false;

    # Add any runtime deps if needed, e.g. requests:
    propagatedBuildInputs = with pkgs.python313Packages; [
      requests
    ];
  };

  # Look up working commit hashes here: https://www.nixhub.io/packages/azure-cli
  # azcli is for some reason not working from nixpkgs
  # Pin tracked as the nixpkgs_azcli_pin flake input, so `nix flake update`
  # and the flake lock cover it.
  nixhubio_azcli = import inputs.nixpkgs_azcli_pin {
    system = pkgs.stdenv.targetPlatform.system;
  };
in {
  xdg.configFile."containers/containers.conf".text = ''
    [engine]
    helper_binaries_dir = ["${pkgs.gvproxy}/bin", "${pkgs.netavark}/bin", "${pkgs.aardvark-dns}/bin", "${pkgs.passt}/bin", "${pkgs.podman}/libexec/podman"]
  '';

  home.packages = with pkgs; [
    # QEMU packages
    qemu
    quickemu
    quickgui
    gvproxy
    virtiofsd

    # Podman packages
    podman
    netavark
    aardvark-dns
    passt # provides pasta

    nixos-icons
    alejandra
    nerd-fonts.jetbrains-mono
    wl-clipboard
    shellcheck

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
        hy
        sysctl
        requests
        argparse
        thefuzz
        datetime
        argparse
        websocket-client
        pyperclip
        openssh
        rapidfuzz
        beautifulsoup4
        lxml
        pdfminer-six
        pdfplumber

        python-tss-sdk
      ]))

    microsoft-edge
    chromium

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
    #docker_29
    #docker-compose

    inetutils

    sops
    age
    inxi

    #tmux

    # Claude tools
    bubblewrap
    socat
    claude-code
    libseccomp
    cmake

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
      nixhubio_azcli.azure-cli-extensions.costmanagement
      nixhubio_azcli.azure-cli-extensions.databricks
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
    openshift
    terraform
    ansible
    powershell
    github-cli

    #Required for Github Copilot
    nodejs_24
    opencode

    firefox

    podman
    podman-compose
    cmake
    gnumake
    gvproxy
    gvisor

    vault

    zstd
  ];
}
