{
  pkgs,
  ...
}: let
  # Call the hyprlock package from the flake
  hyprlock = pkgs.callPackage (import
    (pkgs.fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprlock";
      rev = "main"; # or specify a commit/tag/branch
      sha256 = "sha256-139xsd161n5cfd70zg0l3did4lwcaj2wpz728wpsnird9xb9m1ab";
    })
    {});
in {
  home.packages = with pkgs; [
    hyprlock # Install hyprlock for the user
  ];

  systemd.user.services.hyprlock = {
    description = "Hyprlock screen lock";
    wantedBy = ["default.target"];
    execStart = "${hyprlock}/bin/hyprlock";
  };
}
#{ pkgs ? import <nixpkgs> { } }:
#
#pkgs.stdenv.mkDerivation {
#  pname = "hyprlock";
#  version = "1.0";
#
#  src = pkgs.fetchFromGitHub {
#    owner = "hyprwm";
#    repo = "hyprlock";
#    rev = "main";
#    sha256 = "sha256-139xsd161n5cfd70zg0l3did4lwcaj2wpz728wpsnird9xb9m1ab";
#  };
#
#  buildInputs = with pkgs; [ cmake ];
#
#  buildPhase = ''
#    cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
#    cmake --build ./build --config Release --target hyprlock -j`nproc 2>/dev/null || getconf _NPROCESSORS_CONF`
#  '';
#
#  installPhase = ''
#    #mkdir -p $out/share/rofi/themes
#    #cp $src/*.rasi $out/share/rofi/themes/
#    cmake --install build
#    cp $src $out
#  '';
#}
#

