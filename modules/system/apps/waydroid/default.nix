{
  pkgs,
  ...
}: {
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  programs.adb.enable = true;
}
