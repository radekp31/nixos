{
  pkgs,
  lib,
  ...
}: {
  # Enable Plasma
  services.desktopManager.plasma6 = {
    enable = true;
  };
  # Default display manager for Plasma
  services.displayManager.sddm = {
    enable = true;

    # To use Wayland (Experimental for SDDM)
    wayland.enable = true;
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    elisa
  ];

  xdg.portal = {
    enable = true;
    # This is critical for Plasma 6/Wayland
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      # Include the GTK portal as a fallback for Steam/Electron apps
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = ["kde"];
      };
    };
  };

  boot.kernelModules = ["btusb"];
  boot.kernelParams = ["usbcore.autosuspend=-1"];
}
