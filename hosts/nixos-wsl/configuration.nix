{lib, ...}: {
  imports = [
    ./users.nix
    ./variables.nix
    ../common/default.nix
    ../common/profiles/wsl.nix
    ../../modules/system/apps/nixvim
    ../../modules/system/apps/nix-ld-wsl
    ../../modules/system/hardware/gpu/nvidia-wsl/default.nix
  ];

  # Make WSL GPU libs visible to dynamic linker
  environment.sessionVariables = {
    LD_LIBRARY_PATH = lib.mkBefore "/usr/lib/wsl/lib";
  };

  wsl.useWindowsDriver = true;
  wsl.interop.register = true;

  wsl.ssh-agent.enable = true;

  # WSL user
  wsl.defaultUser = "radekp";
  wsl.interop.includePath = false;

  # Timezone (already UTC in common, but explicit here)
  time.timeZone = "UTC";

  # More conservative GC for WSL
  nix.gc.options = lib.mkForce "--delete-older-than 30d";

  # Unfree packages
  nixpkgs.config.allowUnfree = true;

  # Neovim as editor
  environment.variables.EDITOR = "nvim";

  # Enable SSH
  services.openssh = {
    enable = true;
  };

  # Avoid conflicts with openssh
  systemd.services.sshd.enable = false;

  networking.hostName = "dt-wsl-nix";

  system.stateVersion = "25.05";

  # Enable docker
  # dont forget to add user to "docker" group to run docker without sudo
  virtualisation.docker.enable = true;
}
