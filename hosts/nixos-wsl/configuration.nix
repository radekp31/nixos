{
  config,
  lib,
  ...
}: {
  imports = [
    ./users.nix
    ../common/default.nix
    ../common/profiles/wsl.nix
    ../../modules/system/apps/nixvim
  ];

  # WSL user
  wsl.defaultUser = "radekp";

  # Timezone (already UTC in common, but explicit here)
  time.timeZone = "UTC";

  # More conservative GC for WSL
  nix.gc.options = lib.mkForce "--delete-older-than 30d";

  # Unfree packages
  nixpkgs.config.allowUnfree = true;

  # Neovim as editor
  environment.variables.EDITOR = "nvim";

  # Enable SSH
  services.openssh.enable = true;

  system.stateVersion = "25.05";

  # Enable docker
  # dont forget to add user to "docker" group to run docker without sudo
  virtualisation.docker.enable = true;
}
