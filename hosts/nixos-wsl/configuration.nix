{
  lib,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./users.nix
    ./variables.nix
    ./devbox.nix
    ../common/default.nix
    ../common/profiles/wsl.nix
    ../../modules/system/apps/wsl-nixvim
    ../../modules/system/apps/nix-ld-wsl
    # claude-code comes from nixpkgs_unstable, not from the release input.
    ../../modules/system/apps/claude-code
    ../../modules/system/hardware/gpu/nvidia-wsl/default.nix
  ];

  nixpkgs.config.allowUnfree = true;

  wsl.interop.register = true;

  wsl.ssh-agent.enable = true;

  # WSL user
  wsl.defaultUser = config.my.user.name;
  # Windows PATH entries make zsh typing slow (9P lookups per keystroke).
  # The zsh config aliases the Windows commands in use.
  wsl.interop.includePath = false;

  # Timezone (already UTC in common, but explicit here)
  time.timeZone = "UTC";

  # More conservative GC for WSL
  nix.gc.options = lib.mkForce "--delete-older-than 30d";

  # Enable SSH
  services.openssh = {
    enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    # or: nerd-fonts.fira-code, nerd-fonts.hack, etc.
  ];

  # Avoid conflicts with openssh
  systemd.services.sshd.enable = false;

  networking.hostName = "dt-wsl-nix";

  system.stateVersion = "25.05";

  # Enable docker
  # dont forget to add user to "docker" group to run docker without sudo
  virtualisation.docker.enable = false;
}
