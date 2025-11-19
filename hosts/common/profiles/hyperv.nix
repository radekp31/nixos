{
  pkgs,
  lib,
  ...
}: {
  imports = [
    <nixpkgs/nixos/modules/virtualisation/hyperv-guest.nix>
  ];

  virtualisation.hypervGuest.enable = true;

  # Hyper-V optimized kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_6_6;
  boot.blacklistedKernelModules = ["hyperv_fb" "modesetting" "uio" "uio_hv_generic"];
  boot.kernelModules = ["hv_balloon" "hv_netvsc" "hv_storvsc" "hv_vmbus" "hv_utils" "hv_uio_fcopy"];

  # Graphics for Hyper-V
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-tools
      libva-vdpau-driver
      libvdpau-va-gl
      libva1
      nvidia-vaapi-driver
    ];
  };

  # Video driver for Hyper-V
  services.xserver.videoDrivers = lib.mkDefault ["fbdev"];

  # Disable IPv6 (common for Hyper-V VMs)
  networking.enableIPv6 = lib.mkDefault false;

  # Hyper-V specific packages
  environment.systemPackages = with pkgs; [
    linuxKernel.packages.linux_6_6.hyperv-daemons
    xsel
    xrdp
  ];

  # xRDP for remote desktop
  services.xrdp = {
    enable = lib.mkDefault true;
    openFirewall = lib.mkDefault true;
  };

  networking.firewall.allowedTCPPorts = [3389];
}
