{lib, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ../../common/default.nix
    ../../common/profiles/server.nix
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "/dev/sda";
  };

  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  networking.hostName = "nixos-vps1";

  # Override common timezone
  time.timeZone = "Europe/Prague";

  # Fix for broken $NIX_PATH on this VPS
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
    "nixos-config=/etc/nixos/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
    "/nix/var/nix/profiles/system/channels"
    "home-manager:$HOME/src/github.com/nix-community/home-manager"
  ];

  nixpkgs.flake.source = lib.mkForce "github:nixos/nixpkgs/nixos-24.05";

  system.stateVersion = "25.05";
}
