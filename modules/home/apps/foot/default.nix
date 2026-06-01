# modules/home/apps/foot/default.nix
{
  pkgs,
  lib,
  ...
}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        dpi-aware = "yes";
        font = "JetBrains Mono:size=14.5";
        initial-window-size-chars = "130x35";
      };
      mouse = {
        hide-when-typing = "yes";
      };
      colors-dark = {
        cursor = "181926 f4dbd6";
        foreground = "cad3f5";
        background = "24273a";
        regular0 = "494d64";
        regular1 = "ed8796";
        regular2 = "a6da95";
        regular3 = "eed49f";
        regular4 = "8aadf4";
        regular5 = "f5bde6";
        regular6 = "8bd5ca";
        regular7 = "b8c0e0";
        bright0 = "5b6078";
        bright1 = "ed8796";
        bright2 = "a6da95";
        bright3 = "eed49f";
        bright4 = "8aadf4";
        bright5 = "f5bde6";
        bright6 = "8bd5ca";
        bright7 = "a5adcb";
        "16" = "f5a97f";
        "17" = "f4dbd6";
        selection-foreground = "cad3f5";
        selection-background = "454a5f";
        search-box-no-match = "181926 ed8796";
        search-box-match = "cad3f5 363a4f";
        jump-labels = "181926 f5a97f";
        urls = "8aadf4";
      };
    };
  };
  home.packages = with pkgs; [
    jetbrains-mono
  ];
  systemd.user.services.foot-server = {
    Unit = {
      Description = "Foot Terminal Server";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.foot}/bin/foot --server";
      Restart = "always";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
