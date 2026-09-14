{...}: {
  # Virtualization for nixos-desktop.
  #
  # The user decided on 2026-09-15: quickemu is enough, libvirtd is not.
  # Everything that a devShell CAN hold now lives in flakes/tools#vm:
  #
  #   nix develop /etc/nixos/flakes/tools#vm
  #
  # WHY libvirtd IS GONE
  #
  # libvirtd is a systemd service, so it could never move to a devShell, and
  # unit-libvirtd.service referenced the 963 MiB qemu store path directly. The
  # daemon therefore pinned that closure into every generation. virt-manager,
  # the dconf connection profile, and the libvirtd and qemu-libvirtd group
  # memberships all existed only to serve that daemon, so they went with it.
  #
  # Restore all five together if you ever want virt-manager back. A partial
  # restore gives a GUI that cannot connect.
  #
  # WHAT STAYS, AND WHY IT CANNOT MOVE
  #
  # quickemu still needs KVM from the kernel, and it still needs the setuid
  # USB helper. A devShell provides neither. /dev/kvm is mode 0666 on this
  # host, so no group membership is needed to reach it.

  # nixos-desktop is the only importer and runs an AMD CPU.
  boot.kernelModules = ["kvm-amd"];

  # Installs a setuid spice-client-glib-usb-acl-helper. USB passthrough to a
  # quickemu guest needs it, and a setuid binary cannot come from a devShell.
  virtualisation.spiceUSBRedirection.enable = true;
}
