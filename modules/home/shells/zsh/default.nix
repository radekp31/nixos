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

      fastfetch --config ${pkgs.fastfetch}/share/fastfetch/presets/examples/3.jsonc

      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      #nixpush() {
      #  nix fmt && \
      #  git add -A && \
      #  if ! git diff --cached --quiet; then
      #    git commit -m "$1"
      #  fi && \
      #  nix flake check && \
      #  git push
      #}

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
