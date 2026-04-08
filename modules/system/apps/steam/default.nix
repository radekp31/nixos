{pkgs, ...}: {
  # Steam
  # Dota 2 parameters for Wayland, to force xwayland session to avoid crashes:
  # SDL_VIDEODRIVER=x11 %command% -vulkan
  # use steam launch parameters such as:
  # gamemoderun %command%
  # mangohud %command%
  # gamescope %command%

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATH = "/home/radekp/.steam/root/compatibilitytools.d";
  };

  programs.gamemode.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };

  environment.systemPackages = with pkgs; [
    mangohud
    lutris
    heroic
    bottles
    protonup-ng
  ];
}
