{
  config,
  lib,
  pkgs,
  ...
}: {
  # Vicinae launcher. It replaces KRunner on Plasma. The catppuccin module
  # themes it, because catppuccin.enable is on.
  programs.vicinae = {
    enable = true;
    systemd.enable = true; # starts with graphical-session.target
  };

  # Move Alt+Space and Alt+F2 from KRunner to "vicinae toggle". kglobalaccel
  # separates shortcuts with a tab. kglobalshortcutsrc is mutable Plasma state
  # that kglobalaccel also writes, so set only these two keys. The change
  # applies at the next Plasma login.
  home.activation.vicinaeShortcut = lib.hm.dag.entryAfter ["writeBoundary"] ''
    rc=${config.xdg.configHome}/kglobalshortcutsrc
    kw=${pkgs.kdePackages.kconfig}/bin/kwriteconfig6
    run $kw --file "$rc" --group services --group org.kde.krunner.desktop --key _launch ""
    run $kw --file "$rc" --group services --group vicinae.desktop --key toggle $'Alt+Space\tAlt+F2'
  '';
}
