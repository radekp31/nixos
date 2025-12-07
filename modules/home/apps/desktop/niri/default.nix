#Docs: https://github.com/sodiboo/niri-flake/blob/main/docs.md
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.app.niri.enable = lib.mkEnableOption "niri";

  config = lib.mkIf (config.app.niri.enable) {
    programs.niri = {
      enable = true;
      settings = {
        prefer-no-csd = true;

        environment = {
          DISPLAY = ":0";
        };

        input = {
          keyboard = {
            repeat-rate = 30;
            #repeat-delay = 200;
            #xkb = {};
            numlock = true;
          };

          # Enable if on laptop
          #touchpad = {};

          #mouse = {};
        };

        outputs = {
          "DP-2" = {
            enable = true;
            focus-at-startup = true;
            mode = {
              width = 2560;
              height = 1440;
              refresh = 144.000;
            };
            position = {
              x = 1920;
              y = 0;
            };
          };

          "DP-3" = {
            enable = true;
            mode = {
              width = 1920;
              height = 1080;
              refresh = 60.000;
            };
            position = {
              x = 0;
              y = 0;
            };
          };
        };

        spawn-at-startup = [
          {command = ["noctalia-shell"];}
          #{command = ["xwayland-satellite"];}
        ];

        binds = with config.lib.niri.actions; let
          sh = spawn "sh" "-c";
        in {
          "Super+Return".action.spawn = "${pkgs.foot}/bin/foot";
          "Super+Space".action = spawn "${pkgs.rofi}/bin/rofi" "-show" "drun";
          "Mod+Space".action.spawn = [
            "noctalia-shell"
            "ipc"
            "call"
            "launcher"
            "toggle"
          ];

          "Mod+P".action.spawn = "noctalia-shell ipc call sessionMenu toggle";

          "Mod+C".action.spawn = "noctalia-shell ipc call controlCenter toggle";

          "Mod+S".action.spawn = "noctalia-shell ipc call settings toggle";

          "Super+E".action = spawn "${pkgs.firefox}/bin/firefox";
          "Super+W".action = close-window;

          # Workspace overview
          "Super+Tab".action = toggle-overview;

          # Resize window
          "Super+R".action = switch-preset-window-width;

          # Toggle fullscreen
          "Super+F".action = fullscreen-window;

          # Quit Niri
          "Super+Shift+Q".action = quit;

          # Run Xwayland-satellite
          "Super+X".action.spawn = "xwayland-satellite";

          # # Lock Session
          # "Super+L".action = spawn "${pkgs.systemd}/bin/loginctl" "lock-session";

          # Screenshotting
          #"Print".action = screenshot;

          # Workspaces
          "Super+0".action = focus-workspace 0;
          "Super+1".action = focus-workspace 1;
          "Super+2".action = focus-workspace 2;
          "Super+3".action = focus-workspace 3;
          "Super+4".action = focus-workspace 4;
          "Super+5".action = focus-workspace 5;
          "Super+6".action = focus-workspace 6;
          "Super+7".action = focus-workspace 7;
          "Super+8".action = focus-workspace 8;
          "Super+9".action = focus-workspace 9;
          "Super+Shift+0".action.move-window-to-workspace = [{focus = false;} "0"];
          "Super+Shift+1".action.move-window-to-workspace = [{focus = false;} "1"];
          "Super+Shift+2".action.move-window-to-workspace = [{focus = false;} "2"];
          "Super+Shift+3".action.move-window-to-workspace = [{focus = false;} "3"];
          "Super+Shift+4".action.move-window-to-workspace = [{focus = false;} "4"];
          "Super+Shift+5".action.move-window-to-workspace = [{focus = false;} "5"];
          "Super+Shift+6".action.move-window-to-workspace = [{focus = false;} "6"];
          "Super+Shift+7".action.move-window-to-workspace = [{focus = false;} "7"];
          "Super+Shift+8".action.move-window-to-workspace = [{focus = false;} "8"];
          "Super+Shift+9".action.move-window-to-workspace = [{focus = false;} "9"];

          # Special Keys
          "XF86AudioRaiseVolume".action = sh "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+";
          "XF86AudioLowerVolume".action = sh "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-";
          "XF86AudioMute".action = sh "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle";
        };
      };
    };
  };
}
