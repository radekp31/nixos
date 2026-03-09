{ config, pkgs, lib, ... }:

{
  programs.nix-ld = {
    enable = true;
    # Provide common libs for foreign binaries
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      # add more if some foreign binary complains about missing libs
    ];
  };

}

