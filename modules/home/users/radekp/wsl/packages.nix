{
  pkgs,
  lib,
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

    # Juno tools
    terminator

    # azure-cli comes from stable nixpkgs. On unstable it depends on python
    # fabric, which is broken with invoke 3.x (fabric issue #2376).
    azure-cli
    azure-cli-extensions.ad
    azure-cli-extensions.fzf
    azure-cli-extensions.ssh
    azure-cli-extensions.nsp
    azure-cli-extensions.kusto
    azure-cli-extensions.zones
    azure-cli-extensions.quota
    azure-cli-extensions.portal

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

  programs.zsh.envExtra = ''
    export PATH="$HOME/.local/bin:$PATH"
  '';

  home.activation.installTerminatorCtl = lib.hm.dag.entryAfter ["writeBoundary"] ''
    VENV="$HOME/.juno-ape-venv"
    if ! "$VENV/bin/terminator-ctl" --version >/dev/null 2>&1; then
      ${pkgs.python3}/bin/python3 -m venv "$VENV"
      "$VENV/bin/pip" install --quiet terminator-ctl \
        --extra-index-url "https://artifactory.lab.dynatrace.org/artifactory/api/pypi/ape-pypi-local/simple/"
    fi
    mkdir -p "$HOME/.local/bin"
    install -m755 ${pkgs.writeShellScript "terminator-ctl" ''
      source "$HOME/.juno-ape-venv/bin/activate"
      exec terminator-ctl "$@"
    ''} "$HOME/.local/bin/terminator-ctl"
  '';
}
