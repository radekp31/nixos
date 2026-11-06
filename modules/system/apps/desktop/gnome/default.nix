{
  config,
  pkgs,
  ...
}: {
  # The tuigreet module needs this font: its patched matrix rain uses
  # Cyrillic and Greek glyphs that ter-v22b has.
  console = {
    earlySetup = true;
    font = "ter-v22b"; # Terminus bold, 22px; try ter-v24b or ter-v28b on a 4K screen
    packages = [pkgs.terminus_font];
    #colors = [
    #  "1a1b26" "f7768e" "9ece6a" "e0af68"
    #  "7aa2f7" "bb9af7" "7dcfff" "a9b1d6"
    #  "414868" "f7768e" "9ece6a" "e0af68"
    #  "7aa2f7" "bb9af7" "7dcfff" "c0caf5"
    #];
  };

  services.desktopManager.gnome.enable = true;

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  #services.gnome.core-apps.enable = false;
  #services.gnome.core-developer-tools.enable = false;
  #services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [gnome-tour gnome-user-docs nautilus];

  # Cursor theme: Adwaita, the GNOME default. GNOME already installs it.
  # GNOME reads the cursor from the dconf key below. Plasma writes
  # breeze_cursors into the user dconf database, and that value wins over a
  # system default. The lock makes GNOME ignore the user value.
  programs.dconf.profiles = {
    user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface".cursor-theme = "Adwaita";
          "org/gnome/desktop/background" = {
            picture-uri = "file://${../../../../../extra/wallpapers/reddit1-nixos-wallpapers.png}";
            picture-uri-dark = "file://${../../../../../extra/wallpapers/reddit1-nixos-wallpapers.png}";
            picture-options = "scaled";
          };
        };
        locks = [
          "/org/gnome/desktop/interface/cursor-theme"
          "/org/gnome/desktop/background/picture-uri"
          "/org/gnome/desktop/background/picture-uri-dark"
          "/org/gnome/desktop/background/picture-options"
        ];
      }
    ];
  };

  # GNOME opens the Activities overview after login. GNOME has no setting for
  # this. The extension options (dash-to-panel hide-overview-on-startup, Just
  # Perfection startup-status) did not work on GNOME 50: the extensions get
  # enabled after the startup check. This service waits until the overview
  # opens, then closes it through the OverviewActive D-Bus property. It stops
  # after 10 seconds if the overview does not open.
  systemd.user.services.hide-overview-on-login = {
    description = "Close the GNOME overview after login";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    path = [config.systemd.package pkgs.gnugrep];
    serviceConfig.Type = "oneshot";
    script = ''
      prop="org.gnome.Shell /org/gnome/Shell org.gnome.Shell OverviewActive"
      for _ in $(seq 20); do
        if busctl --user get-property $prop | grep -q true; then
          exec busctl --user set-property $prop b false
        fi
        sleep 0.5
      done
    '';
  };

  # XWayland applications (for example Steam) read these variables.
  environment.sessionVariables = {
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";
  };

  programs.gnome-disks.enable = true;

  services.gnome.core-apps.enable = true;

  services.gnome.sushi.enable = true;

  services.gnome.core-os-services.enable = true;

  services.gnome.tinysparql.enable = true;

  services.gnome.gnome-settings-daemon.enable = true;

  services.gnome.localsearch.enable = true;

  services.desktopManager.gnome.debug = true;

  # Set default programs
  xdg.mime = {
    enable = true;
    defaultApplications = {
      # Set Nemo file explorer as default
      # See nautilus included in excludePackages
      "inode/directory" = "nemo.desktop";
      "application/x-gnome-saved-search" = "nemo.desktop";
    };
  };

  environment.systemPackages = with pkgs; [
    nemo # File explorer
    gdm-settings
    #
    gnomeExtensions.just-perfection
    #gnomeExtensions.arc-menu
    #gnomeExtensions.dash-to-panel
    ##gnome-shell-extensions set
    #gnomeExtensions.applications-menu
    #gnomeExtensions.auto-move-windws
    ##gnomeExtensions.mount-meter
    #gnomeExtensions.launch-new-instance
    ##gnomeExtensions.light-style
    #gnomeExtensions.native-window-placement
    #gnomeExtensions.places-status-indicator
    #gnomeExtensions.screenshot-window-sizer
    #gnomeExtensions.status-icons
    #gnomeExtensions.system-monitor
    #gnomeExtensions.user-themes
    gnomeExtensions.window-list
    ##gnomeExtensions.windowsNavigator
    #gnomeExtensions.workspace-indicator
    # vicinae reads the window list and the clipboard through this extension.
    gnomeExtensions.vicinae
    #gnomeExtensions.tweaks-in-system-menu
  ];
}
