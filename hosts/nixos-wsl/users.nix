{pkgs, ...}: {
  imports = [
    ../../modules/home/apps/tmux
  ];

  programs.zsh.enable = true;

  environment.shells = with pkgs; [zsh bash];

  users.users = {
    radekp = {
      isNormalUser = true;
      createHome = true;
      extraGroups = ["wheel" "docker"];
      group = "users";
      home = "/home/radekp";
      shell = pkgs.zsh;
    };
  };
}
