{pkgs, ...}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";

        #font = "monospace:size=13";
        dpi-aware = "yes";
        # Include the color theme file
        #include = "~/.config/foot/themes/dracula";
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

  #xdg.configFile."foot/themes/catppuccin-mocha".text = ''
  #  # Catppuccin Mocha

  #  [colors]
  #  cursor=f5e0dc cdd6f4
  #  foreground=cdd6f4
  #  background=1e1e2e
  #  regular0=45475a  # black
  #  regular1=f38ba8  # red
  #  regular2=a6e3a1  # green
  #  regular3=f9e2af  # yellow
  #  regular4=89b4fa  # blue
  #  regular5=f5c2e7  # magenta
  #  regular6=94e2d5  # cyan
  #  regular7=a6adc8  # white
  #  bright0=585b70   # bright black
  #  bright1=f37799   # bright red
  #  bright2=89d88b   # bright green
  #  bright3=ebd391   # bright yellow
  #  bright4=74a8fc   # bright blue
  #  bright5=f2aede   # bright magenta
  #  bright6=6bd7ca   # bright cyan
  #  bright7=bac2de   # bright white
  #'';

  #xdg.configFile."foot/themes/catppuccin-macchiato".text = ''
  #  # Catppuccin Macchiato

  #  [colors]
  #  cursor=f4dbd6 cad3f5
  #  foreground=cad3f5
  #  background=24273a
  #  regular0=494d64  # black
  #  regular1=ed8796  # red
  #  regular2=a6da95  # green
  #  regular3=eed49f  # yellow
  #  regular4=8aadf4  # blue
  #  regular5=f5bde6  # magenta
  #  regular6=8bd5ca  # cyan
  #  regular7=a5adcb  # white
  #  bright0=5b6078   # bright black
  #  bright1=ec7486   # bright red
  #  bright2=8ccf7f   # bright green
  #  bright3=e1c682   # bright yellow
  #  bright4=78a1f6   # bright blue
  #  bright5=f2a9dd   # bright magenta
  #  bright6=63cbc0   # bright cyan
  #  bright7=b8c0e0   # bright white
  #'';
}
