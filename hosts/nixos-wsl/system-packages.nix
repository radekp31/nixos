{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    neovim
    vim
    wget
    curl
    git
    htop
    tmux
  ];
}
