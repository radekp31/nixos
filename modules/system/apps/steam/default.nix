{
  pkgs,
  config,
  ...
}: {
  # Steam
  # Dota 2 parameters for Wayland, to force xwayland session to avoid crashes:
  # SDL_VIDEODRIVER=x11 %command% -vulkan
  # use steam launch parameters such as:
  # gamemoderun %command%
  # mangohud %command%
  # gamescope %command%

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  #programs.gamemode.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    gamescopeSession.enable = false;

    # NVIDIA tuning for games only. extraEnv puts it inside the Steam FHS
    # environment, not in every process.
    package = pkgs.steam.override {
      extraEnv = {
        __GL_GSYNC_ALLOWED = "1";
        __GL_VRR_ALLOWED = "1";
        __GL_THREADED_OPTIMIZATIONS = "0";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    mangohud
    lutris
    bottles
    protonup-ng
  ];
  systemd.user.services.steam = {
    description = "Steam Background";
    serviceConfig = {
      # Use the configured package, not pkgs.steam. The plain package
      # ignores programs.steam settings, including extraEnv.
      ExecStart = "${config.programs.steam.package}/bin/steam -silent";
      Restart = "on-failure";
    };
    wantedBy = ["graphical-session.target"];
  };
}
