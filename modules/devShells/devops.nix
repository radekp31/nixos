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
in
  pkgs.mkShell {
    packages = with pkgs; [
      (python313.withPackages (ps:
        with ps; [
          # More packages
          openpyxl
          collections-extended
          pandas
          numpy
        ]))

      kubectl
      awscli2
      google-cloud-sdk
      pkgs25_05.azure-cli
      terraformer
      aztfexport
      dig
      google-cloud-sdk
      fzf
      jq
      git
      gh # GitHub CLI
      docker-compose
      helm
      awscli2
      google-cloud-sdk
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

    shellHook = ''
      export DEVSHELL_NAME="devops"
      export NIXPKGS_ALLOW_UNFREE="1"
    '';
  }
