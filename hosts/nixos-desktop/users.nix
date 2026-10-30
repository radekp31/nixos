{
  pkgs,
  config,
  ...
}: {
  programs.zsh.enable = true;

  users = {
    users = {
      radekp = {
        isNormalUser = true;
        description = config.my.user.fullName;
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "input"
          "adbusers"
          "plugdev"
          "docker"
          "dialout"
        ];
        packages = with pkgs; [
          zsh
        ];
      };
    };
  };
}
