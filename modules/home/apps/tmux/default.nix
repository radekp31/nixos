# ======================== TMUX CHEAT SHEET ========================
# prefix = Ctrl-Space   (written "P" below)
# Hierarchy: server > session (ticket) > window (tab) > pane (split)
#
# --- SESSIONS (one per Jira ticket) ---
# P N        new session: prompts for name, creates here, switches (custom)
# P s        fuzzy session picker with fzf (custom)
# P w        tree of all sessions and windows; x in tree kills item
# Ctrl-l     session list, no prefix (custom; may clash with vim-navigator)
# P $        rename session
# P X        kill session and ALL its windows, asks y/n (custom)
# P d        detach, session keeps running
# shell:     tmux ls | tmux new -d -s NAME | tmux kill-session -t NAME
#
# --- WINDOWS (tabs inside a session) ---
# P c        new window in current directory (custom)
# P 1..9     go to window number (base index is 1)
# P n / P p  next / previous window
# P ,        rename window
# P W        kill window, asks y/n (custom)
#
# --- PANES (splits inside a window) ---
# P v        split side by side, current directory (custom)
# P %        split side by side (default)
# P "        split stacked (default)
# P h/j/k/l  move between panes (vi keys)
# P H/J/K/L  resize pane by 5 cells
# P z        zoom pane to full window, press again to restore
# P x        kill pane, asks y/n
#
# --- COPY MODE (vi keys; mouse is on) ---
# P [        enter copy mode
# v          start selection
# y          copy selection and leave (goes to Windows clipboard via OSC 52)
# q          leave copy mode
# / or ?     search forward / backward
#
# --- PLUGINS ---
# P Ctrl-s   resurrect: save sessions
# P Ctrl-r   resurrect: restore sessions
# Ctrl-h/j/k/l  vim-tmux-navigator: move between vim and tmux panes
#
# --- GENERAL ---
# P r        reload config (custom)
# P :        tmux command prompt
# P ?        list all key bindings
# tmux list-keys | grep -E ' (N|W|X) '   check custom bindings are loaded
# ==================================================================
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

       # Prevent focus-click from entering copy mode
       unbind -T root MouseDrag1Pane

       # --- Rest of your existing extraConfig ---
       set -g status-position top
       set -g set-titles on
       set -g set-titles-string "#S: #W"


       set-option -g status-left-length 50
       #set-option -g status-right-length 50
       set-option -g status-left "#[fg=cyan,bold]#S#[default] | "
       set-option -g status-right "#[fg=green]%H:%M#[default] %d-%b-%y"
       set-option -g status-justify left
       set-option -g status-interval 1

      # WSL: hide the status bar. The session name shows in the Windows Terminal tab.
      if-shell 'grep -qi microsoft /proc/version 2>/dev/null' \
        'set -g status off' \
        'set -g status on'

       set-option -g pane-border-style "fg=white"
       set-option -g pane-active-border-style "fg=cyan"

       bind-key s display-popup -E "tmux list-sessions -F '#{session_name}' | fzf | xargs tmux switch-client -t"
       bind-key -n C-l choose-session
       bind-key r source-file ~/.config/tmux/tmux.conf \\; display "Config reloaded"

       bind-key v split-window -h -c "#{pane_current_path}"
       bind-key c new-window -c "#{pane_current_path}"

       set-option -sa terminal-overrides ",foot:Tc,xterm*:Tc,konsole:Tc"

       # Hex, not an ANSI name: a little darker than the taerminal background
       # (#26282a). Change it if you change the alacritty theme.
       set -g status-style "bg=#1c1d1f,fg=white"
       set -g message-style "bg=default,fg=cyan"
       set -g mode-style "bg=blue,fg=black"
       set -g window-status-style "fg=brightblack"
       set -g window-status-current-style "fg=blue,bold"

       # Keep the client alive when its session is killed: jump to another session
       # instead of detaching. Without this, killing a session closes your tmux view.
       set -g detach-on-destroy off

       # prefix + N: ask for a ticket name, create the session here, switch to it
       bind-key N command-prompt -p "ticket:" "new-session -d -s '%%' -c '#{pane_current_path}' ; switch-client -t '%%'"

       # prefix + W: kill the current window (and its panes), with confirmation
       bind-key W confirm-before -p "Kill window #I:#W? (y/n)" kill-window

       # prefix + X: kill the current session with ALL its windows, with confirmation
       bind-key X confirm-before -p "Kill session #S and all its windows? (y/n)" kill-session


    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      resurrect
      continuum
    ];
  };
}
