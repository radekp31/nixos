{ ... }: {
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    #extraConfig = builtins.readFile ./wezterm.lua;
  };

  # Symlink for Windows access (adjust target path as needed)
  #xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
}
