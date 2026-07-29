# General desktop settings
{pkgs, ...}: {
  # Enable networking (already in common/default.nix, so remove or keep for clarity)
  # networking.networkmanager.enable = true;  # Remove - duplicate from common

  environment.sessionVariables = {
    #ensure any GTK app launched under KDE or Wayland can reliably locate its interface schemas
    XDG_DATA_DIRS = [
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
    ];
  };

  # Sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Printing
  services.printing.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # dconf for GNOME/GTK apps configuration
  programs.dconf.enable = true;

  # XDG Base Directory
  #environment.variables = {
  #  XDG_CACHE_HOME = "$HOME/.cache";
  #  XDG_CONFIG_HOME = "$HOME/.config";
  #  XDG_DATA_HOME = "$HOME/.local/share";
  #  XDG_STATE_HOME = "$HOME/.local/state";
  #};

  # Desktop fonts - system-wide

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = ["Noto Sans" "DejaVu Sans"];
        serif = ["Noto Serif" "DejaVu Serif"];
        monospace = ["FiraCode Nerd Font" "JetBrainsMono Nerd Font"];
      };
    };
  };

  fonts.packages = with pkgs; [
    noto-fonts
    cantarell-fonts
    liberation_ttf
    dejavu_fonts

    dejavu_fonts
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
  ];

  # Desktop system packages - only system-critical
  environment.systemPackages = with pkgs; [
    xdg-utils # Desktop integration (xdg-open, etc.)
    pciutils # Hardware info (lspci)
    smartmontools # Drive monitoring
    lm_sensors # Temperature/fan sensors
  ];

  # Enable XDG portal
  #xdg.portal = {
  #  enable = true;
  #  extraPortals = [
  #  ];
  #  config = {
  #    common = {
  #      default = ["kde"];
  #    };
  #  };
  #};

  #environment.pathsToLink = [
  #  "/share/applications"
  #  "/share/xdg-desktop-portal"
  #];
}
