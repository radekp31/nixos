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

      nixpush() {
        nix fmt && \
        git add -A && \
        if ! git diff --cached --quiet; then
          git commit -m "$1"
        fi && \
        nix flake check && \
        git push
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
