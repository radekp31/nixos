#{config, pkgs, lib, stdenv, fetchFromGitHub, rofi }:
{pkgs ? import <nixpkgs> {}}:
pkgs.stdenv.mkDerivation {
  pname = "tokyonight-rofi-theme";
  version = "1.0";

  src = pkgs.fetchFromGitHub {
    owner = "w8ste";
    repo = "Tokyonight-rofi-theme";
    rev = "main";
    sha256 = "sha256-lv8VJO9Iw221X94zuEi+JOvT5fCGFn+6ppHZHimGfi4=";
  };

  buildInputs = [pkgs.rofi];

  installPhase = ''
    mkdir -p $out/share/rofi/themes
    cp $src/*.rasi $out/share/rofi/themes/
  '';
}
