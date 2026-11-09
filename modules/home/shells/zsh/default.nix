{
  config,
  pkgs,
  ...
}: {
  programs.fzf.enable = true;

  programs.bat.enable = true;

  programs.zsh = {
    enable = true;
    # Pin the dotfile directory to $HOME. The default moves to
    # $XDG_CONFIG_HOME/zsh once home.stateVersion reaches 26.05.
    # That move also relocates .zsh_history, which holds real data.
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestion = {
      enable = true;
    };
    envExtra = ''
      #export NIXPKGS_ALLOW_UNFREE=1
      export C='/mnt/c'
      #export MANPAGER='nvim +Man!'

    '';
    profileExtra = ''
    '';

    initContent = ''

        if command -v tmux &>/dev/null \
          && [[ -n "$PS1" ]] \
          && [[ "$TERM" != screen* ]] \
          && [[ "$TERM" != tmux* ]] \
          && [[ -z "$TMUX" ]]; then
          exec tmux new-session -A -s mgmt -c /etc/nixos
        fi

        setopt HIST_IGNORE_SPACE

        # Add devshell name to prompt if available
        if [ -n "$DEVSHELL_NAME" ]; then
          PROMPT=$(echo $PROMPT | sed "s/╭─/╭─%F{cyan} ❄  [$DEVSHELL_NAME]%f /")
        fi

        if [[ $- == *i* ]]; then
          if grep -qi microsoft /proc/version &> /dev/null; then
            # Keep the System, Shell and Storage lines. Remove colors, logo and icons.
            # Color the labels light blue (ANSI 94).
            microfetch | LC_ALL=C sed -n -E 's/\x1b\[[0-9;]*m//g; s/\xee\x98\xa1 //; s/^.*  (System|Shell|Storage \(\/\))(.*)/\x1b[94m\1\x1b[0m\2/p'
          fi
        fi

        if [[ $- == *i* ]]; then
          __last_rebuild=$(stat -c %Y /nix/var/nix/profiles/system 2>/dev/null || echo 0)
          __days_stale=$(( ($(date +%s) - __last_rebuild) / 86400 ))
          if (( __days_stale >= 14 )); then
            echo "System not rebuilt in ''${__days_stale} days (last: $(date -d @''${__last_rebuild} '+%Y-%m-%d'))."
          fi
          unset __last_rebuild __days_stale
        fi

        if [[ $- == *i* ]]; then
          if grep -qi microsoft /proc/version &> /dev/null; then
            firefox-wsl() {
              env \
                -u LD_LIBRARY_PATH \
                -u LIBRARY_PATH \
                MOZ_DISABLE_GPU_ACCELERATION=1 \
                MOZ_X11_EGL=0 \
                MOZ_ENABLE_WAYLAND=0 \
                LIBGL_ALWAYS_INDIRECT=1 \
                firefox "$@"
            }
          fi
        fi

        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

        setopt EXTENDED_GLOB

        if [[ -n "$WSL_DISTRO_NAME" ]]; then
          aws-login() {
            mkdir -p ~/.aws
            local cred_file=(/mnt/c/Users/radek.polasek/Downloads/credentials*(om[1]))
            if [[ -f $cred_file ]]; then
              cp -vi "$cred_file" ~/.aws/credentials
              chmod 600 ~/.aws/credentials
              echo "✓ AWS credentials updated"
            else
              echo "✗ No credentials file found in Downloads"
              return 1
            fi
          }

          alias aws-logout='rm -f ~/.aws/credentials'

          # wsl.interop.includePath is off. Call these Windows commands by full path.
          alias code="'/mnt/c/Program Files/Microsoft VS Code/bin/code'"
          alias clip.exe='/mnt/c/Windows/system32/clip.exe'

          # Override gnzh: drop user@host, keep path + git + time
          setopt PROMPT_SUBST

          _wsl_git_prompt() {
            local branch dirty=""
            branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
            git diff --quiet 2>/dev/null || dirty="*"
            git diff --cached --quiet 2>/dev/null || dirty="*"
            echo " %F{yellow}‹''${branch}''${dirty}›%f"
          }

          PROMPT='%F{grey}╭─%f %F{green}%~%f$(_wsl_git_prompt)
      %F{grey}╰─➤%f  '
          #RPROMPT='%F{grey}%D{%H:%M}%f'
        fi

        set_subscription() {
          az account list --query '[].{name:name, id:id}' -o tsv \
            | fzf \
            | awk '{print $2}' \
            | xargs -I {} az account set --subscription "{}" && echo "Current subscription: "$(az account show --query name -o tsv)
        }

        nixpush() {
          local message="$1"
          if [ -f flake.nix ]; then
            nix fmt || return 1
          fi
          git add -A
          if git diff --cached --quiet; then
            echo "No changes to commit"
            return 0
          fi
          git commit -m "$message" && git push
        }

        rgf() {
          if [ -z "$1" ]; then
            echo "Usage: rgf <search_term>"
            return 1
          fi
          local result=$(
            rga --color=always --line-number --no-heading --smart-case "$*" |
            fzf --ansi \
                --delimiter ':' \
                --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
                --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
          )
          if [ -n "$result" ]; then
            local file=$(echo "$result" | cut -d: -f1)
            local line=$(echo "$result" | cut -d: -f2)
            nvim "+$line" "$file"
          fi
        }

        eval "$(direnv hook zsh)"

    '';

    shellAliases = {
      devops = "nix develop \".#devops\" --command zsh -i";
      ll = "ls -lah --color=auto";
      grep = "grep --color=auto";
      vi = "nvim";
      vim = "nvim";
      cat = "bat -pp";
      tf = "terraform";
      tfr = "terraformer";
      k = "kubectl";
      pf = "fzf --preview='type -p bat >/dev/null && bat --color=always --style=numbers {} || less {}'"; # preview files, use bat, if not available failover to less, Shift+UP/Down to scroll
      az-account-set = "az account list --query '[].{name:name, id:id}' -o tsv | fzf | awk '{print $2}' | xargs -I {} az account set --subscription \"{}\" && echo \"Current subscription: \"$(az account show --query name -o tsv)";
      lsblk = "lsblk -o NAME,FSTYPE,SIZE,LABEL,MOUNTPOINT,UUID";
    };
    oh-my-zsh = {
      enable = true;
      theme = "gnzh"; #Disable for manual prompt overriding
      plugins = [
        "git"
        "virtualenv"
        "copyfile"
        "command-not-found"
        "fzf"
        "sudo"
        "azure"
        "aws"
        "gcloud"
        "kubectl"
      ];
    };
  };
  home.packages = with pkgs; [
    zsh-fzf-tab
    zsh-fzf-history-search
  ];
}
