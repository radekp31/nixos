{ ... }: {
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    #extraConfig = builtins.readFile ./wezterm.lua;
  };

  # Symlink for Windows access (adjust target path as needed), Windows wont pick the config automatically
  # Either: cp /mnt/c/Users/radek.polasek/.config/wezterm/wezterm.lua /etc/nixos/modules/home/apps/wezterm/wezterm.lua
  #
  # Or:  Copy-Item "\\wsl$\NixOS\etc\nixos\modules\home\apps\wezterm\wezterm_win.lua" -Destination "$env:USERPROFILE\.config\wezterm\wezterm.lua" -Force
  
}
