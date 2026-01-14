{
  pkgs,
  pkgs25_05,
  pkgs_unstable,
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
in {
  home.packages = with pkgs; [
    (python313.withPackages (ps:
      with ps; [
        openpyxl
        collections-extended
        pandas
        numpy
      ]))
    gh
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

    sops
    age
    inxi

    tmux
    (pkgs25_05.azure-cli.withExtensions [
      pkgs25_05.azure-cli-extensions.storage-preview
      pkgs25_05.azure-cli-extensions.azure-devops
      pkgs25_05.azure-cli-extensions.resource-graph
      pkgs25_05.azure-cli-extensions.ssh
      pkgs25_05.azure-cli-extensions.quota

      pkgs25_05.azure-cli-extensions.nsp
      pkgs25_05.azure-cli-extensions.kusto
      pkgs25_05.azure-cli-extensions.graphservices

      pkgs25_05.azure-cli-extensions.fzf
      pkgs25_05.azure-cli-extensions.dynatrace
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
    pkgs_unstable.terraform
    ansible
  ];
}
