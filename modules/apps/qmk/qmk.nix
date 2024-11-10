#/etc/nixos/modules/usb/usb.nix
{ config, pkgs, lib, ...}:

{
  hardware.keyboard.qmk.enable = true;

  environment.systemPackages = with pkgs; [
    via
  ];
  services.udev.packages = [pkgs.via];

}

