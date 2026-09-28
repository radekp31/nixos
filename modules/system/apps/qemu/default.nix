{...}: {
  # Virtualization for nixos-desktop: quickemu, no libvirtd. The VM tools
  # live in a devShell:
  #
  #   nix develop /etc/nixos/flakes/tools#vm
  #
  # virt-manager needs libvirtd, the dconf connection profile, and the libvirtd
  # and qemu-libvirtd group memberships. Restore all of them together, or the
  # GUI cannot connect.
  #
  # quickemu needs KVM from the kernel and the setuid USB helper. A devShell
  # provides neither. /dev/kvm is mode 0666 on this host, so no group
  # membership is needed to reach it.

  # nixos-desktop is the only importer and runs an AMD CPU.
  boot.kernelModules = ["kvm-amd"];

  # Installs a setuid spice-client-glib-usb-acl-helper. USB passthrough to a
  # quickemu guest needs it, and a setuid binary cannot come from a devShell.
  virtualisation.spiceUSBRedirection.enable = true;
}
