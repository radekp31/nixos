{
  config,
  pkgs,
  ...
}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # Ensures Ctrl+R and Ctrl+T keybindings are correctly hooked up
  };
  programs.bat.enable = true;

  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    sessionVariables = {
      FZF_DEFAULT_COMMAND = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules";
      FZF_CTRL_T_COMMAND = "$FZF_DEFAULT_COMMAND";
      FZF_DEFAULT_OPTS = ''
        --color=spinner:#f38ba8,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f38ba8
        --color=marker:#f38ba8,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
        --layout=reverse
        --height=40%
        --border
      '';
    };

    initContent = ''
      # ==============================================================================
      # 1. Environment & Performance Options
      # ==============================================================================
      setopt autocd extendedglob nomatch notify histignorealldups sharehistory
      unsetopt beep

      HISTSIZE=50000
      SAVEHIST=50000
      HISTFILE=~/.zsh_history

      # Emacs line-editing bindings
      bindkey -e

      # Fast completion caching (rebuild .zcompdump once every 24 hours)
      autoload -Uz compinit
      if [[ -n ''${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
        compinit
      else
        compinit -C
      fi

      # ==============================================================================
      # 2. Gnzh-Style Clean Multi-Line Prompt
      # ==============================================================================
      setopt prompt_subst

      _gnzh_git_prompt() {
        local branch dirty=""
        branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
        git diff --quiet 2>/dev/null || dirty="*"
        git diff --cached --quiet 2>/dev/null || dirty="*"
        echo " %F{yellow}‹''${branch}''${dirty}›%f"
      }

      PROMPT='%F{grey}╭─%f %F{green}%~%f$(_gnzh_git_prompt)
      %F{grey}╰─➤%f '
      #RPROMPT='%F{242}%D{%H:%M}%f'

      # ==============================================================================
      # 3. fzf / ripgrep-all Blazing Fast Integration
      # ==============================================================================
      # Telescope-style interactive grep/search with fullscreen and binary exclusion filter
      fgr() {
        local initial_query="''${1:-.}"
        rga --line-number --no-heading --color=always --smart-case --glob '!*.{pdf,zip,tar,gz}' "''${initial_query}" |
          fzf --ansi \
              --height=100% \
              --layout=reverse \
              --border \
              --delimiter : \
              --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
              --preview-window 'up,75%,border-bottom,+{2}+3/3'
      }
    '';
  };

  home.packages = with pkgs; [
    ripgrep-all
    fd
  ];
}
