{ pkgs, ... }: {
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
    shortcut = "Space";

    terminal = "tmux-256color";

    extraConfig = ''
      # 1. Enable native terminal clipboard sync (OSC 52)
      set -g set-clipboard on

      # 2. Configure tmux-yank for Wayland / KDE
      # User 'Ctrl+<Shortcut>+[' to enter vim style copy mode
      set -g @override_copy_command 'wl-copy'

      # Enable mouse support for click-and-drag selection directly to clipboard
      set -g mouse on

      # Vi mode selection bindings
      bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
      bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "wl-copy"

      # Optional: Bind 'p' in normal tmux mode to paste directly from Wayland clipboard
      bind-key p run "wl-paste --no-newline | tmux load-buffer - && tmux paste-buffer"

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

      new-session -d -s mgmt -c "/etc/nixos"
      new-session -d -s scratch -c "/tmp"
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      resurrect
      continuum
      yank # Handles yanks and mouse selection copying
    ];
  };
}
