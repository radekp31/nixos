{
  pkgs,
  lib,
  ...
}: {
  users.users.root = {
    shell = lib.mkForce pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzoVRVWpxFy1dOe0vVrtv2c/i9GixoyUDKpgsuruSG2 radekp@nixos-desktop"
    ];
  };
}
