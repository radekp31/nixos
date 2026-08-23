{pkgs, ...}: let
  wallpaper = pkgs.stdenvNoCC.mkDerivation {
    name = "sddm-wallpaper";
    src = ./piqsels.com-id-oanpz.jpg;
    dontUnpack = true;
    installPhase = "cp $src $out";
  };

  # UUID for the WezTerm window rule
  weztermRuleId = "d5c6279a-3677-4d2b-b846-94f70a458720";

  # Script that updates kwinrulesrc idempotently using kreadconfig6/kwriteconfig6
  kwinRuleScript = pkgs.writeShellScript "kwin-set-rules" ''
    KCONFIG="$HOME/.config/kwinrulesrc"

    # 1. Append rule UUID to [General] rules array if not present
    EXISTING_RULES="$(${pkgs.kdePackages.kconfig}/bin/kreadconfig6 --file "$KCONFIG" --group "General" --key "rules" 2>/dev/null || true)"
    if ! echo "$EXISTING_RULES" | grep -q "${weztermRuleId}"; then
      if [ -z "$EXISTING_RULES" ]; then
        NEW_RULES="${weztermRuleId}"
      else
        NEW_RULES="$EXISTING_RULES,${weztermRuleId}"
      fi
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$KCONFIG" --group "General" --key "rules" "$NEW_RULES"
    fi

    # 2. Write key-value options for WezTerm rule
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$KCONFIG" --group "${weztermRuleId}" --key "Description" "Wezterm no title"
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$KCONFIG" --group "${weztermRuleId}" --key "Enabled" "true"
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$KCONFIG" --group "${weztermRuleId}" --key "noborder" "true"
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$KCONFIG" --group "${weztermRuleId}" --key "noborderrule" "2"
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$KCONFIG" --group "${weztermRuleId}" --key "wmclass" "org.wezfurlong.wezterm"
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$KCONFIG" --group "${weztermRuleId}" --key "wmclassmatch" "1"

    # 3. Reload KWin configuration
    ${pkgs.kdePackages.qttools}/bin/qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
  '';
in {
  services.desktopManager.plasma6.enable = true;

  # SDDM configuration
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;

    extraPackages = with pkgs.kdePackages; [
      qtsvg
      qtdeclarative
    ];
  };

  environment.systemPackages = with pkgs; [
    kdePackages.kcalc
    kde-rounded-corners
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

  systemd.user.services = {
    plasma-wallpaper = {
      description = "Set Plasma wallpaper";
      wantedBy = ["plasma-workspace.target"];
      after = ["plasma-workspace.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-wallpaperimage ${wallpaper}";
      };
    };

    # Injects KWin rule without overwriting user-added GUI rules
    plasma-kwin-rules = {
      description = "Inject KWin window rules";
      wantedBy = ["plasma-workspace.target"];
      after = ["plasma-workspace.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${kwinRuleScript}";
      };
    };
  };
}
