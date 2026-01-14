# Config here: https://www.youtube.com/watch?v=DzNmUNvnB04&t
{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    baseIndex = 1;
    resizeAmount = 5;
    escapeTime = 0;
    historyLimit = 15000;
    customPaneNavigationAndResize = true;
    aggressiveResize = true;
    newSession = true;
    #shortcut = "b";
    shortcut = "Space";
    terminal = "screen-256color";

    extraConfig = ''
      # Status bar styling
      set-option -g status-left-length 50
      set-option -g status-right-length 50

      # Show current session and window list
      set-option -g status-left "#[fg=cyan,bold]#S#[default] | "
      set-option -g status-right "#[fg=green]%H:%M#[default] %d-%b-%y"
      set-option -g status-justify left
      set-option -g status-interval 1

      # Pane borders
      set-option -g pane-border-style "fg=white"
      set-option -g pane-active-border-style "fg=cyan"

      # Session switcher with fzf
      bind-key s display-popup -E "tmux list-sessions -F '#{session_name}' | fzf | xargs tmux switch-client -t"

      # Additional useful bindings
      bind-key -n C-l choose-session
      bind-key r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

      # Improved split bindings
      bind-key v split-window -h -c "#{pane_current_path}"
      bind-key c new-window -c "#{pane_current_path}"

      # VI mode navigation
      bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
      bind-key -T copy-mode-vi 'y' send-keys -X copy-selection-and-cancel

      # Use terminal colorscheme
      set-option -sa terminal-overrides ",xterm*:Tc"

    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      resurrect
      continuum
      yank
    ];
  };
}
