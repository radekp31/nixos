{pkgs, ...}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";

        #font = "monospace:size=13";
        dpi-aware = "yes";
        # Include the color theme file
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
}
