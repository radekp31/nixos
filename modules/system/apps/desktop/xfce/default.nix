{
  ...
}: {
  services.xserver = {
    enable = true;
    xkb.layout = "us";

    desktopManager = {
      xterm.enable = true;
      xfce.enable = true;
    };

    displayManager.lightdm.enable = true;
  };

  services.displayManager.defaultSession = "xfce";
}
