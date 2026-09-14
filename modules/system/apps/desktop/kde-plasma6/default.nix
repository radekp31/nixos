{
  pkgs,
  lib,
  ...
}: {
  services.desktopManager.plasma6.enable = true;

  # Plasma 6 enables the Orca screen reader by default. Orca then enables
  # speech-dispatcher, which pulls mbrola-voices at 644 MiB. Nobody on this
  # host uses a screen reader. The user confirmed the removal on 2026-09-15.
  # Re-enable both if anybody needs text to speech.
  services.orca.enable = lib.mkForce false;
  services.speechd.enable = lib.mkForce false;

  # SDDM configuration
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";

    extraPackages = with pkgs; [
      kdePackages.qtsvg
      kdePackages.qtdeclarative
      sddm-astronaut
    ];
  };

  environment.systemPackages = with pkgs; [
    kdePackages.kcalc
    kde-rounded-corners
    kdePackages.sddm-kcm
    # Required so the theme directory gets linked into
    # /run/current-system/sw/share/sddm/themes. extraPackages above only
    # feeds the Qt/QML plugin path, it does not link the theme itself.
    sddm-astronaut
  ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    elisa
  ];

  programs.kdeconnect.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = ["kde"];
  };
}
