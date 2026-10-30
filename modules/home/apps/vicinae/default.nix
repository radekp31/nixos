{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: {
  # Vicinae launcher. It replaces KRunner on Plasma. The catppuccin module
  # themes it, because catppuccin.enable is on.
  programs.vicinae = {
    enable = true;
    systemd.enable = true; # starts with graphical-session.target
    # catppuccin sets iconTheme to "Catppuccin <Flavor> <Accent>". No package
    # installs a theme with that name, so vicinae shows no app icons. Use the
    # GTK icon theme (catppuccin Papirus) instead.
    settings.theme = lib.genAttrs ["dark" "light"] (_: {
      iconTheme = lib.mkForce config.gtk.iconTheme.name;
    });
  };

  # GNOME: Super+Tab opens vicinae. GNOME binds Super+Tab to the app switcher
  # by default, so move the app switcher to Super+comma. This replaces the
  # whole custom-keybindings list. Add other custom shortcuts here too.
  dconf.settings = {
    "org/gnome/desktop/wm/keybindings".switch-applications = ["<Super>comma"];
    "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
      "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    ];
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Vicinae launcher";
      binding = "<Super>Tab";
      command = "${lib.getExe config.programs.vicinae.package} open";
    };
  };

  # Plasma: move Alt+Space and Alt+F2 from KRunner to "vicinae toggle".
  # kglobalaccel separates shortcuts with a tab. kglobalshortcutsrc is mutable
  # Plasma state that kglobalaccel also writes, so set only these two keys. The
  # change applies at the next Plasma login. Runs only on hosts with Plasma.
  home.activation.vicinaeShortcut = lib.mkIf osConfig.services.desktopManager.plasma6.enable (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      rc=${config.xdg.configHome}/kglobalshortcutsrc
      kw=${pkgs.kdePackages.kconfig}/bin/kwriteconfig6
      run $kw --file "$rc" --group services --group org.kde.krunner.desktop --key _launch ""
      run $kw --file "$rc" --group services --group vicinae.desktop --key toggle $'Alt+Space\tAlt+F2'
    ''
  );
}
