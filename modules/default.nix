# modules/default.nix

{ config, pkgs, ... }:

let
  gitVars = import ./apps/git/variables.nix;
in

{
  # Import other modules and pass the variables
  imports = [
    ./apps/git/default.nix
    ./apps/vbox/vbox.nix
    ./usb/usb.nix
  ];

}
