{
  pkgs,
  config,
  ...
}: {
  programs.zsh.enable = true;

  environment.shells = with pkgs; [zsh bash];

  users.users = {
    radekp = {
      isNormalUser = true;
      createHome = true;
      extraGroups = ["wheel" "docker" "kvm"];
      group = "users";
      home = config.my.user.home;
      shell = pkgs.zsh;
    };
  };
}
