{pkgs, ...}: {
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

           # nixpush() {
           #   git reset && nix fmt && git add . && nix flake check && git commit -m "$1" && git push
           # }
           nixpush() {
        git add -A && \
        nix fmt && \
        git add -A && \  # Add again after formatting
        nix flake check && \
        git commit -m "$1" && \
        git push
      }

    '';
    shellAliases = {
      ll = "ls -lah --color=auto";
      grep = "grep --color=auto";
      vi = "nvim";
      vim = "nvim";
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
