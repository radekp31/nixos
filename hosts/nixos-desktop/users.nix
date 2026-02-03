{pkgs, ...}: {
  programs.zsh.enable = true;

  users = {
    users = {
      radekp = {
        isNormalUser = true;
        description = "Radek Polasek";
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "input"
	  "adbusers"
	  "plugdev"
        ];
        packages = with pkgs; [
          zsh
        ];
      };
    };
  };
}
