{...}: {
  # fzf, bat, and tmux use the 16 terminal colors (ANSI names), not catppuccin.
  # They then follow the terminal theme: alacritty on the desktop and the
  # Windows Terminal palette on WSL.
  programs.fzf.defaultOptions = ["--color=16"];

  programs.bat = {
    enable = true;
    config.theme = "ansi"; # the 16 terminal colors
  };

  programs.tmux.extraConfig = ''
    # Hex, not an ANSI name: a little darker than the taerminal background
    # (#26282a). Change it if you change the terminal theme.
    set -g status-style "bg=#1c1d1f,fg=white"
    set -g message-style "bg=default,fg=cyan"
    set -g mode-style "bg=blue,fg=black"
    # Tabs: a gray a little lighter than the bar, and blue for the current
    # tab. The spaces in the formats pad each tab.
    set -g window-status-style "bg=#3a3c3e,fg=white"
    set -g window-status-current-style "bg=blue,fg=black,bold"
    set -g window-status-format " #I:#W#F "
    set -g window-status-current-format " #I:#W#F "
  '';
}
