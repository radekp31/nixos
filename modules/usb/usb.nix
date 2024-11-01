#/etc/nixos/modules/usb/usb.nix
{ config, pkgs, lib, ...}:

{
	#Automount USB devices
	services.devmon.enable = true;
	services.gvfs.enable = true;
	services.udisks2.enable = true;
	services.udev.extraRules = ''
     		ACTION=="add", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", RUN{program}+="${pkgs.systemd}/bin/systemd-mount --no-block --automount=yes --collect $devnode /media"       
	'';
}

