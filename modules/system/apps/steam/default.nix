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

  # gamemode stays off. It was disabled here during the 2026-09-08 Dota 2
  # debugging and the user has not asked for it back.
  #programs.gamemode.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    # No gamescope. Confirmed 2026-09-14. Do not re-enable.
    # A gamescope session broke Dota 2 on 2026-09-08: the Steam launch
    # options called the binary, and the rebuild removed it.
    # Explicit false beats a comment: the intent survives a future edit.
    gamescopeSession.enable = false;

    # NVIDIA tuning for games only. Before 2026-09-14 these sat in
    # environment.sessionVariables on the host and applied to every process.
    # extraEnv puts them inside the Steam FHS environment.
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
