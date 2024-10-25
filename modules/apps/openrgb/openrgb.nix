{ config, pkgs, lib, ...}:


{
	services.hardware.openrgb.enable = true;
	services.hardware.openrgb.motherboard = "amd";
}
