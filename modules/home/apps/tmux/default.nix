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
    shortcut = "Space";

    terminal = "tmux-256color";

    extraConfig = ''

      set -g status-interval 5

      # Copy: tmux sends the selection to the terminal with OSC 52.
      # WezTerm sets the real clipboard. This works on WSL and on native Linux.
      set -s set-clipboard on
      # Let nvim and other applications send their own OSC 52 through tmux.
      set -g allow-passthrough on

      # Paste: use the WezTerm default binding Ctrl+Shift+V.

      set -g mouse on

      # Vi mode selection bindings
      bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
      bind-key -T copy-mode-vi 'y' send-keys -X copy-selection-and-cancel
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-no-clear

      # --- Rest of your existing extraConfig ---
      set -g status-position top
      set -g set-titles on
      set -g set-titles-string "#S: #W"

      set-option -g status-left-length 50
      set-option -g status-right-length 50
      set-option -g status-left "#[fg=cyan,bold]#S#[default] | "
      set-option -g status-right "#[fg=green]%H:%M#[default] %d-%b-%y"
      set-option -g status-justify left
      set-option -g status-interval 1

      set-option -g pane-border-style "fg=white"
      set-option -g pane-active-border-style "fg=cyan"

      bind-key s display-popup -E "tmux list-sessions -F '#{session_name}' | fzf | xargs tmux switch-client -t"
      bind-key -n C-l choose-session
      bind-key r source-file ~/.config/tmux/tmux.conf \\; display "Config reloaded"

      bind-key v split-window -h -c "#{pane_current_path}"
      bind-key c new-window -c "#{pane_current_path}"

      set-option -sa terminal-overrides ",foot:Tc,xterm*:Tc,konsole:Tc"

    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      resurrect
      continuum
    ];
  };
}
