{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        decorations = "Full"; # Explicitly requests native title bar and window controls
        dimensions = {
          columns = 130;
          lines = 35;
        };
        padding = {
          x = 8;
          y = 8;
        };
      };

      font = {
        size = 16.0; # Increased font size
        normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
      };

      scrolling = {
        history = 10000;
        multiplier = 3; # Increases mouse wheel scroll speed
      };

      terminal.shell = {
        program = "${pkgs.tmux}/bin/tmux";
        args = ["new-session" "-A" "-s" "main"];
      };

      colors = {
        # Catppuccin Macchiato Palette
        primary = {
          background = "#24273a";
          foreground = "#cad3f5";
        };
        cursor = {
          text = "#181926";
          cursor = "#f4dbd6";
        };
        selection = {
          text = "#cad3f5";
          background = "#454a5f";
        };
        normal = {
          black = "#494d64";
          red = "#ed8796";
          green = "#a6da95";
          yellow = "#eed49f";
          blue = "#8aadf4";
          magenta = "#f5bde6";
          cyan = "#8bd5ca";
          white = "#b8c0e0";
        };
        bright = {
          black = "#5b6078";
          red = "#ed8796";
          green = "#a6da95";
          yellow = "#eed49f";
          blue = "#8aadf4";
          magenta = "#f5bde6";
          cyan = "#8bd5ca";
          white = "#a5adcb";
        };
      };
    };
  };

  home.packages = with pkgs; [
    jetbrains-mono
  ];
}
