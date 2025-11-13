{
  pkgs,
  ...
}: {
  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = ["your_username"];

  virtualisation.libvirtd.enable = true;

  boot.kernelModules = ["kvm-amd" "kvm-intel"];

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

  # Define system packages
  environment.systemPackages = with pkgs; [
    qemu_kvm
    spice-gtk
    spice-protocol
    spice-autorandr
    spice-vdagent
    spice-vdagent
    virt-viewer
    virt-manager
    OVMF
  ];
}
