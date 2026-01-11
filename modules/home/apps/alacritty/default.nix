{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty-graphics;
    settings = {
      font.size = 14.5;
    };
    theme = "dracula";
    #themePackage = pkgs.alacritty-theme;
  };
}
