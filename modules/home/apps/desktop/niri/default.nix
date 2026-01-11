#Docs: https://github.com/sodiboo/niri-flake/blob/main/docs.md
{
  config,
  pkgs,
  ...
}: {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
  };

  programs.niri = {
    enable = true;
    settings = {
      prefer-no-csd = true;

      layout = {
        gaps = 5;
        border = {
          width = 2;
          active = "c099ff";
        };
        shadow.enable = false;
        preset-column-widths = [
          {proportion = 1. / 3.;}
          {proportion = 1. / 2.;}
          {proportion = 2. / 3.;}
        ];

        focus-ring = {
          enable = true;
          width = 1.5;
          active = {
            color = "#c099ff";
          };
          inactive = {
            color = "#444a73";
          };
        };
      };

      window-rules = [
        # Firefox starts fullscreen
        {
          matches = [
            {app-id = ".*";}
          ];
          open-maximized = true;
        }
      ];

      gestures = {
        hot-corners.enable = false;
      };

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
        {command = ["xwayland-satellite" ":0"];}
      ];

      binds = with config.lib.niri.actions; let
        sh = spawn "sh" "-c";
      in {
        # Hotkey overlay
        "Mod+Shift+Slash".action = show-hotkey-overlay;

        # Open programs
        "Super+Return".action.spawn = "${pkgs.alacritty}/bin/alacritty";
        "Mod+Space".action.spawn = ["noctalia-shell" "ipc" "call" "launcher" "toggle"];

        "Super+S".action.spawn = ["noctalia-shell" "ipc" "call" "settings" "toggle"];
        #"Super+Alt+L".action = spawn "swaylock";
        #"Super+Alt+L".action.spawn = ["swaylock" "--screenshots" "--ignore-empty-password" "--daemonize" "--indicator-caps-lock" "--indicator" "--clock" "--show-failed-attempts" "--indicator-idle-visible"];
        "Super+Alt+L".action.spawn = [
          "swaylock"
          "--screenshots"
          "--clock"
          "--effect-blur"
          "10x5"
          "--indicator"
          "--indicator-idle-visible"
          "--indicator-radius"
          "100"
          "--fade-in"
          "0.4"
          "--indicator-thickness"
          "3"
          "--indicator-caps-lock"
          "--ring-color"
          "00000000"
          "--key-hl-color"
          "34bdebff"
          "--bs-hl-color"
          "ed8796ff"
          "--inside-color"
          "00000000"
          "--inside-clear-color"
          "00000000"
          "--inside-ver-color"
          "00000000"
          "--inside-wrong-color"
          "00000000"
          "--ring-clear-color"
          "00000000"
          "--ring-wrong-color"
          "00000000"
          "--ring-ver-color"
          "00000000"
          "--line-color"
          "00000000"
          "--text-color"
          "8a8a8aff"
          "--text-clear-color"
          "f2d5cfff"
          "--text-ver-color"
          "8a8a8aff"
          "--text-wrong-color"
          "ed8796ff"
          "--effect-vignette"
          "0.5:0.5"
          "--effect-compose"
          "color=000000aa"
        ];
        # Toggle screen reader
        "Super+Alt+S" = {
          action = sh "pkill orca || exec orca";
          allow-when-locked = true;
        };

        # Volume controls
        "XF86AudioRaiseVolume" = {
          action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
          allow-when-locked = true;
        };
        "XF86AudioLowerVolume" = {
          action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
          allow-when-locked = true;
        };
        "XF86AudioMute" = {
          action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          allow-when-locked = true;
        };
        "XF86AudioMicMute" = {
          action = sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          allow-when-locked = true;
        };

        # Media controls
        "XF86AudioPlay" = {
          action = sh "playerctl play-pause";
          allow-when-locked = true;
        };
        "XF86AudioStop" = {
          action = sh "playerctl stop";
          allow-when-locked = true;
        };
        "XF86AudioPrev" = {
          action = sh "playerctl previous";
          allow-when-locked = true;
        };
        "XF86AudioNext" = {
          action = sh "playerctl next";
          allow-when-locked = true;
        };

        # Brightness controls
        "XF86MonBrightnessUp" = {
          action = spawn "brightnessctl" "--class=backlight" "set" "+10%";
          allow-when-locked = true;
        };
        "XF86MonBrightnessDown" = {
          action = spawn "brightnessctl" "--class=backlight" "set" "10%-";
          allow-when-locked = true;
        };

        # Overview
        "Mod+O" = {
          action = toggle-overview;
          repeat = false;
        };

        # Close window
        "Mod+Q" = {
          action = close-window;
          repeat = false;
        };

        # Focus navigation
        "Mod+Left".action = focus-column-left;
        "Mod+Down".action = focus-window-down;
        "Mod+Up".action = focus-window-up;
        "Mod+Right".action = focus-column-right;
        "Mod+H".action = focus-column-left;
        "Mod+J".action = focus-window-down;
        "Mod+K".action = focus-window-up;
        "Mod+L".action = focus-column-right;

        # Move windows
        "Mod+Ctrl+Left".action = move-column-left;
        "Mod+Ctrl+Down".action = move-window-down;
        "Mod+Ctrl+Up".action = move-window-up;
        "Mod+Ctrl+Right".action = move-column-right;
        "Mod+Ctrl+H".action = move-column-left;
        "Mod+Ctrl+J".action = move-window-down;
        "Mod+Ctrl+K".action = move-window-up;
        "Mod+Ctrl+L".action = move-column-right;

        # Focus first/last column
        "Mod+Home".action = focus-column-first;
        "Mod+End".action = focus-column-last;
        "Mod+Ctrl+Home".action = move-column-to-first;
        "Mod+Ctrl+End".action = move-column-to-last;

        # Focus monitors
        "Mod+Shift+Left".action = focus-monitor-left;
        "Mod+Shift+Down".action = focus-monitor-down;
        "Mod+Shift+Up".action = focus-monitor-up;
        "Mod+Shift+Right".action = focus-monitor-right;
        "Mod+Shift+H".action = focus-monitor-left;
        "Mod+Shift+J".action = focus-monitor-down;
        "Mod+Shift+K".action = focus-monitor-up;
        "Mod+Shift+L".action = focus-monitor-right;

        # Move column to monitor
        "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
        "Mod+Shift+Ctrl+Down".action = move-column-to-monitor-down;
        "Mod+Shift+Ctrl+Up".action = move-column-to-monitor-up;
        "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
        "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
        "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
        "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
        "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

        # Workspace navigation
        "Mod+Page_Down".action = focus-workspace-down;
        "Mod+Page_Up".action = focus-workspace-up;
        "Mod+U".action = focus-workspace-down;
        "Mod+I".action = focus-workspace-up;
        "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
        "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
        "Mod+Ctrl+U".action = move-column-to-workspace-down;
        "Mod+Ctrl+I".action = move-column-to-workspace-up;

        # Move workspace
        "Mod+Shift+Page_Down".action = move-workspace-down;
        "Mod+Shift+Page_Up".action = move-workspace-up;
        "Mod+Shift+U".action = move-workspace-down;
        "Mod+Shift+I".action = move-workspace-up;

        # Mouse wheel workspace navigation
        "Mod+WheelScrollDown" = {
          action = focus-workspace-down;
          cooldown-ms = 150;
        };
        "Mod+WheelScrollUp" = {
          action = focus-workspace-up;
          cooldown-ms = 150;
        };
        "Mod+Ctrl+WheelScrollDown" = {
          action = move-column-to-workspace-down;
          cooldown-ms = 150;
        };
        "Mod+Ctrl+WheelScrollUp" = {
          action = move-column-to-workspace-up;
          cooldown-ms = 150;
        };

        # Mouse wheel column navigation
        "Mod+WheelScrollRight".action = focus-column-right;
        "Mod+WheelScrollLeft".action = focus-column-left;
        "Mod+Ctrl+WheelScrollRight".action = move-column-right;
        "Mod+Ctrl+WheelScrollLeft".action = move-column-left;

        "Mod+Shift+WheelScrollDown".action = focus-column-right;
        "Mod+Shift+WheelScrollUp".action = focus-column-left;
        "Mod+Ctrl+Shift+WheelScrollDown".action = move-column-right;
        "Mod+Ctrl+Shift+WheelScrollUp".action = move-column-left;

        # Workspace by index
        "Mod+1".action = focus-workspace 1;
        "Mod+2".action = focus-workspace 2;
        "Mod+3".action = focus-workspace 3;
        "Mod+4".action = focus-workspace 4;
        "Mod+5".action = focus-workspace 5;
        "Mod+6".action = focus-workspace 6;
        "Mod+7".action = focus-workspace 7;
        "Mod+8".action = focus-workspace 8;
        "Mod+9".action = focus-workspace 9;
        #"Mod+Ctrl+1".action = move-window-to-workspace 1;
        #"Mod+Ctrl+2".action = move-window-to-workspace 2;
        #"Mod+Ctrl+3".action = move-window-to-workspace 3;
        #"Mod+Ctrl+4".action = move-window-to-workspace 4;
        #"Mod+Ctrl+5".action = move-window-to-workspace 5;
        #"Mod+Ctrl+6".action = move-window-to-workspace 6;
        #"Mod+Ctrl+7".action = move-window-to-workspace 7;
        #"Mod+Ctrl+8".action = move-window-to-workspace 8;
        #"Mod+Ctrl+9".action = move-window-to-workspace 9;
        "Super+Ctrl+0".action.move-column-to-workspace = [{focus = false;} "0"];
        "Super+Ctrl+1".action.move-column-to-workspace = [{focus = false;} "1"];
        "Super+Ctrl+2".action.move-column-to-workspace = [{focus = false;} "2"];
        "Super+Ctrl+3".action.move-column-to-workspace = [{focus = false;} "3"];
        "Super+Ctrl+4".action.move-column-to-workspace = [{focus = false;} "4"];
        "Super+Ctrl+5".action.move-column-to-workspace = [{focus = false;} "5"];
        "Super+Ctrl+6".action.move-column-to-workspace = [{focus = false;} "6"];
        "Super+Ctrl+7".action.move-column-to-workspace = [{focus = false;} "7"];
        "Super+Ctrl+8".action.move-column-to-workspace = [{focus = false;} "8"];
        "Super+Ctrl+9".action.move-column-to-workspace = [{focus = false;} "9"];

        # Column management
        "Mod+BracketLeft".action = consume-or-expel-window-left;
        "Mod+BracketRight".action = consume-or-expel-window-right;
        "Mod+Comma".action = consume-window-into-column;
        "Mod+Period".action = expel-window-from-column;

        # Window sizing
        "Mod+R".action = switch-preset-column-width;
        "Mod+Shift+R".action = switch-preset-window-height;
        "Mod+Ctrl+R".action = reset-window-height;
        "Mod+F".action = maximize-column;
        "Mod+Shift+F".action = fullscreen-window;
        "Mod+Ctrl+F".action = expand-column-to-available-width;

        # Centering
        "Mod+C".action = center-column;
        "Mod+Ctrl+C".action = center-visible-columns;

        # Fine width adjustments
        "Mod+Minus".action = set-column-width "-10%";
        "Mod+Equal".action = set-column-width "+10%";
        "Mod+Shift+Minus".action = set-window-height "-10%";
        "Mod+Shift+Equal".action = set-window-height "+10%";

        # Floating windows
        "Mod+V".action = toggle-window-floating;
        "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

        # Tabbed display
        "Mod+W".action = toggle-column-tabbed-display;

        # Screenshots
        #"Print".action = screenshot;
        #"Ctrl+Print".action = screenshot-screen;
        #"Alt+Print".action = screenshot-window;

        # Escape hatch
        "Mod+Escape" = {
          action = toggle-keyboard-shortcuts-inhibit;
          allow-inhibiting = false;
        };

        # Quit
        "Mod+Shift+E".action = quit;
        "Ctrl+Alt+Delete".action = quit;

        # Power off monitors
        "Mod+Shift+P".action = power-off-monitors;
      };
    };
  };
  #};
}
