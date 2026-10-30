{
  config,
  pkgs,
  ...
}: {
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  #services.gnome.core-apps.enable = false;
  #services.gnome.core-developer-tools.enable = false;
  #services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [gnome-tour gnome-user-docs];

  # Cursor theme: Adwaita, the GNOME default. GNOME already installs it.
  # GNOME reads the cursor from the dconf key below. Plasma writes
  # breeze_cursors into the user dconf database, and that value wins over a
  # system default. The lock makes GNOME ignore the user value.
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".cursor-theme = "Adwaita";
      locks = ["/org/gnome/desktop/interface/cursor-theme"];
    }
  ];

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

  services.desktopManager.gnome.debug = true ;

  environment.systemPackages = with pkgs; [
    gdm-settings
    
    gnomeExtensions.blur-my-shell
    gnomeExtensions.just-perfection
    gnomeExtensions.arc-menu
    gnomeExtensions.dash-to-panel
    #gnome-shell-extensions set
    gnomeExtensions.applications-menu
    gnomeExtensions.auto-move-windows
    #gnomeExtensions.mount-meter
    gnomeExtensions.launch-new-instance
    #gnomeExtensions.light-style
    gnomeExtensions.native-window-placement
    gnomeExtensions.places-status-indicator
    gnomeExtensions.screenshot-window-sizer
    gnomeExtensions.status-icons
    gnomeExtensions.system-monitor
    gnomeExtensions.user-themes
    gnomeExtensions.window-list
    #gnomeExtensions.windowsNavigator
    gnomeExtensions.workspace-indicator
    gnomeExtensions.vicinae
    gnomeExtensions.tweaks-in-system-menu
  ];
}
