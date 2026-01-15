{pkgs, ...}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";

        #font = "monospace:size=13";
        dpi-aware = "yes";
        # Include the color theme file
        include = "~/.config/foot/themes/dracula";
        #font = "DejaVu Sans Mono:size=11";
        font = "JetBrains Mono:size=14.5";
        # Explicitly specify bold variants too
        #font-bold = "DejaVu Sans Mono:style=Bold:size=11";

        #font-italic = "DejaVu Sans Mono:style=Oblique:size=11";
        #font-bold-italic = "DejaVu Sans Mono:style=Bold Oblique:size=11";
      };

      mouse = {
        hide-when-typing = "yes";
      };
    };
  };

  home.packages = with pkgs; [
    jetbrains-mono
  ];
  xdg.configFile."foot/themes/dracula".text = ''
    # Dracula

    #[colors-dark]
    [colors]
    cursor=282a36 f8f8f2
    foreground=f8f8f2
    background=282a36
    regular0=000000  # black
    regular1=ff5555  # red
    regular2=50fa7b  # green
    regular3=f1fa8c  # yellow
    regular4=bd93f9  # blue
    regular5=ff79c6  # magenta
    regular6=8be9fd  # cyan

    regular7=bfbfbf  # white
    bright0=4d4d4d   # bright black
    bright1=ff6e67   # bright red

    bright2=5af78e   # bright green
    bright3=f4f99d   # bright yellow
    bright4=caa9fa   # bright blue
    bright5=ff92d0   # bright magenta
    bright6=9aedfe   # bright cyan
    bright7=e6e6e6   # bright white
  '';
}
