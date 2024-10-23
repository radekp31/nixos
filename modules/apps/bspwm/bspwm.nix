#/etc/nixos/modules/apps/bswpm/bspwm.nix

{ config, pkgs, lib, ...}:

{
	services.xserver.windowsManager.bspwm = {
		enable = true;
		configFile = "../../configs/bspwm/bspwmrc";
		sxhkd.configFile = "../../configs/bspwm/sxhkdrc"; 
	};

}
