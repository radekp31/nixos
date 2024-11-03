#/etc/nixos/modules/usb/usb.nix
{ config, pkgs, lib, ...}:

{
	#Automount USB devices
	services.devmon.enable = true;
	services.gvfs.enable = true;
	services.udisks2.enable = true;
}

