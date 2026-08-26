{ config, pkgs, lib, ... }:

let
  # pkgs.dwl is already the 0.8 release; only add the hot-reload patch and
  # our own config.h on top of it.
  patchedDwl =
    (pkgs.dwl.override {
      configH = ./config.h;
    }).overrideAttrs (oldAttrs: {
      # The upstream patch targets the dwl main branch, which has drifted
      # from the v0.8 tag. -F3 lets most hunks apply despite the offset;
      # patches/hot-reload-0.8.patch additionally fixes the one hunk whose
      # context text differs (a comment wording change) so it applies clean.
      patchFlags = [ "-p1" "-F3" ];
      patches = (oldAttrs.patches or [ ]) ++ [
        ./patches/hot-reload-0.8.patch
      ];
    });
in
{
  programs.dwl = {
    enable = true;
    package = patchedDwl;

    extraSessionCommands = ''
      systemctl --user import-environment \
        DISPLAY \
        WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_TYPE
    '';
  };

  environment.systemPackages = with pkgs; [
    foot
    fuzzel
    yambar
    xdg-terminal-exec
  ];

  environment.etc."yambar/config.yml".text = ''
    bar:
      location: top
      height: 24
      background: 222222ff
      foreground: d0d0d0ff
      font: monospace:size=10
      right:
        - clock:
            content:
              - string:
                  text: "{time}"
  '';

  systemd.user.services.yambar = {
    description = "Yambar status bar";
    wantedBy = [ "dwl-session.target" ];
    partOf = [ "dwl-session.target" ];
    after = [ "dwl-session.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.yambar}/bin/yambar";
      Restart = "on-failure";
      RestartSec = "1s";
    };
  };
}
