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

  sddmTheme = pkgs.stdenv.mkDerivation {
    name = "sddm-breeze-custom";
    buildCommand = ''
      mkdir -p $out/share/sddm/themes/breeze-custom
      cp -r ${pkgs.kdePackages.plasma-desktop}/share/sddm/themes/breeze/. \
        $out/share/sddm/themes/breeze-custom/
      chmod -R u+w $out/share/sddm/themes/breeze-custom
      sed -i "s|background=.*|background=${wallpaper}|" \
        $out/share/sddm/themes/breeze-custom/theme.conf
    '';
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

      # Aurorae window decorations
      mkdir -p $out/share/aurorae/themes
      cp -r aurorae/TokyoNight $out/share/aurorae/themes/

      # Plasma Look-and-Feel (check plasma/ subdir structure if this fails)
      mkdir -p $out/share/plasma/look-and-feel
      cp -r plasma/look-and-feel/. $out/share/plasma/look-and-feel/

      # Color schemes
      mkdir -p $out/share/color-schemes
      cp -r colorscheme/. $out/share/color-schemes/

      # Wallpapers
      mkdir -p $out/share/wallpapers
      cp -r wallpapers/. $out/share/wallpapers/

      runHook postInstall
    '';
  };
in {
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "breeze-custom";
    extraPackages = with pkgs.kdePackages; [
      breeze-icons
      breeze
    ];
    };

  environment.systemPackages = with pkgs; [
    kdePackages.kcalc
    kde-rounded-corners
    plasma-tokyo-night
    sddmTheme
  ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    elisa
    (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
      [General]
      background=${wallpaper}
    '')
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

    # Lock screen wallpaper
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
