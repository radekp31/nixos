{pkgs, ...}: {
  programs.zsh.enable = true;

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
