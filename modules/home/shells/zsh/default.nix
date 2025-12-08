{pkgs, ...}: {
  programs.fzf.enable = true;

  programs.bat.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestion = {
      enable = true;
    };
    initContent = ''
      export NIXPKGS_ALLOW_UNFREE=1
      export EDITOR='nvim'
      export VISUAL='nvim'
      export C='/mnt/c'

      if [[ $- == *i* ]]; then
        # Check if running inside WSL
        if grep -qi microsoft /proc/version &> /dev/null; then
          fastfetch --config ${pkgs.fastfetch}/share/fastfetch/presets/examples/3.jsonc
        fi
      fi

      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # WSL-specific configuration
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
      fi


      nixpush() {
        local message="$1"

        # Format
        nix fmt && git add -A

        if git diff --cached --quiet; then
          echo "✅ No changes to commit"
          return 0
        fi

        # Count unpushed commits
        local unpushed=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")

        if [ "$unpushed" -gt 0 ]; then
          # Squash all unpushed commits + new changes
          echo "🔄 Squashing $unpushed unpushed commit(s) + new changes..."
          git reset --soft @{upstream} 2>/dev/null || {
            echo "⚠️  No upstream branch, creating fresh commit..."
            git reset --soft HEAD~''${unpushed}
          }
          git commit -m "$message"
          echo "✅ Force pushing..."
          git push --force-with-lease
        else
          # Normal push (first commit or already pushed)
          echo "✅ Creating new commit..."
          git commit -m "$message" && git push
        fi
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
    '';
    shellAliases = {
      ll = "ls -lah --color=auto";
      grep = "grep --color=auto";
      vi = "nvim";
      vim = "nvim";
      cat = "bat -pp";
    };
    oh-my-zsh = {
      enable = true;
      theme = "gnzh";
      plugins = [
        "copyfile"
        "git"
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
}
