{
  pkgs,
  lib,
  ...
}: let
  wallpaper = pkgs.stdenvNoCC.mkDerivation {
    name = "sddm-wallpaper";
    src = ./piqsels.com-id-oanpz.jpg;
    dontUnpack = true;
    installPhase = "cp $src $out";
  };

  plasma-tokyo-night = pkgs.stdenv.mkDerivation {
    name = "plasma-tokyo-night";
    src = pkgs.fetchFromGitHub {
      owner = "Jayy-Dev";
      repo = "Plasma-Tokyo-Night";
      rev = "plasma-6";
      hash = "sha256-Y+ta28tOYA5woAj9bcTunz5+9o3QUdKgeBAB//c48gk=";
    };

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/aurorae/themes
      cp -r aurorae/TokyoNight $out/share/aurorae/themes/
      mkdir -p $out/share/plasma/look-and-feel
      cp -r plasma/look-and-feel/. $out/share/plasma/look-and-feel/
      mkdir -p $out/share/color-schemes
      cp -r colorscheme/. $out/share/color-schemes/
      mkdir -p $out/share/wallpapers
      cp -r wallpapers/. $out/share/wallpapers/
      runHook postInstall
    '';
  };
in {
  services.desktopManager.plasma6.enable = true;

  # 2. Configure SDDM to target the true Qt6 structure theme
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    
    # Sugar Candy relies on the graphical SVG core layout elements inside raw components
    extraPackages = with pkgs.kdePackages; [
      qtsvg
      qtdeclarative
    ];
  };

  environment.systemPackages = with pkgs; [
    kdePackages.kcalc
    kde-rounded-corners
    plasma-tokyo-night
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

  environment.etc = {
    "xdg/kdeglobals".text = ''
      [KDE]
      LookAndFeelPackage=com.github.Jayy-Dev.Plasma.Tokyo.Night
      [General]
      ColorScheme=TokyoNight
    '';
    "xdg/kwinrc".text = ''
      [org.kde.kdecoration2]
      library=org.kde.kwin.aurorae
      theme=__aurorae__svg__TokyoNight
    '';
    "xdg/plasmarc".text = ''
      [Theme]
      name=com.github.Jayy-Dev.Plasma.Tokyo.Night
    '';
    "xdg/kscreenlockerrc".text = ''
      [Greeter]
      WallpaperPlugin=org.kde.image
      [Greeter][Wallpaper][org.kde.image][General]
      Image=file://${wallpaper}
    '';
  };

  systemd.user.services.plasma-wallpaper = {
    description = "Set Plasma wallpaper";
    wantedBy = ["plasma-workspace.target"];
    after = ["plasma-workspace.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage ${wallpaper}";
    };
  };
}
