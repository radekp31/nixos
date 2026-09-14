{...}: {
  programs.virt-manager.enable = true;

  virtualisation.libvirtd.enable = true;

  # nixos-desktop is the only importer and runs an AMD CPU.
  boot.kernelModules = ["kvm-amd"];

  virtualisation.spiceUSBRedirection.enable = true;

  users.users.radekp.extraGroups = ["libvirtd" "qemu-libvirtd"];

  programs.dconf = {
    enable = true;
    profiles = {
      radekp.databases = [
        {
          settings = {
            "org/virt-manager/virt-manager/connections" = {
              autoconnect = ["qemu:///system"];
              uris = ["qemu:///system"];
            };
          };
        }
      ];
    };
  };

  # The standalone tools moved to flakes/tools#vm on 2026-09-15.
  #
  #   nix develop /etc/nixos/flakes/tools#vm
  #
  # Only the daemon side stays here. libvirtd is a systemd service, so it
  # cannot live in a devShell, and it requires qemu directly:
  # unit-libvirtd.service references the 963 MiB qemu store path. That closure
  # therefore stays while libvirtd stays enabled. programs.virt-manager
  # supplies the polkit rules that the GUI needs, so it stays too.
  #
  # OVMF and swtpm now come from virtualisation.libvirtd.qemu, not from this
  # list. Check those options before you report a missing UEFI or TPM VM.
}
