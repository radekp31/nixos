{ ...}: {
  #programs.zsh.enable = true;

  users.users = {
    radekp = {
      isNormalUser = true;
      createHome = true;
      extraGroups = ["wheel"];
      group = "users";
      home = "/home/radekp";
      #shell = pkgs.zsh;
    };
  };
}
