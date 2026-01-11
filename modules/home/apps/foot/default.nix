{...}: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";

        font = "monospace:size=13";
        dpi-aware = "yes";
        # Include the color theme file
        include = "~/.config/foot/themes/noctalia";
      };

      mouse = {
        hide-when-typing = "yes";
      };
    };
  };
}
