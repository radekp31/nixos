#{config, pkgs, lib, stdenv, fetchFromGitHub, rofi }:

{ pkgs ? import <nixpkgs> { } }:

pkgs.stdenv.mkDerivation {
  pname = "tokyonight-rofi-theme";
  version = "1.0";

  src = pkgs.fetchFromGitHub {
    owner = "w8ste";
    repo = "Tokyonight-rofi-theme";
    rev = "main";
    sha256 = "sha256-SxcZCn7ZKLJbm5GZZPeDbm8C6OI+zeiipsrN0ldDOoU=";
  };

  buildInputs = [ pkgs.rofi ];

  installPhase = ''
    mkdir -p $out/share/rofi/themes
    cp $src/*.rasi $out/share/rofi/themes/
  '';
}

