{inputs, ...}: {
  # import the home manager module
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home.file.".cache/noctalia/wallpapers.json" = {
    text = builtins.toJSON {
      defaultWallpaper = "~/Pictures/wallpapers/sdnixos.png";
      wallpapers = {
        "DP-2" = "~/Pictures/wallpapers/sdnixos.png";
        "DP-3" = "~/Pictures/wallpapers/sdnixos.png";
      };
    };
  };

  # configure options
  programs.noctalia-shell = {
    enable = true;
    settings = {
      # configure noctalia here; defaults will
      # be deep merged with these attributes.
      bar = {
        density = "comfortable";
        position = "top";
        showCapsule = true;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "SystemMonitor";
            }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "none";
            }
          ];
          right = [
            {
              id = "Volume";
            }
            {
              formatHorizontal = "HH:mm";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
            {
              id = "NotificationHistory";
            }
          ];
        };
      };
      colorSchemes = {
        #useWallpaperColors = true;
        predefinedScheme = "Tokyo Night";
        darkMode = true;
        #schedulingMode = "automatic";  # Auto-switch based on time
        matugenSchemeType = "scheme-tonal-spot"; # Better color harmony
        generateTemplatesForPredefined = true;
      };

      templates = {
        gtk = true;
        qt = true;
        niri = true;
        foot = true; # If you use kitty terminal
      };
      general = {
        #avatarImage = "/home/drfoobar/.face";
        radiusRatio = 0.2;
      };
      location = {
        monthBeforeDay = true;
        name = "Czech Republic, Brno";
      };
    };
    # this may also be a string or a path to a JSON file,
    # but in this case must include *all* settings.
  };
}
