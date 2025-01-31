{ config, pkgs, ... }:

{
  # Enable dconf program
  programs.dconf.enable = true;

  # Create group
  users.groups = {
    gcis = {
      gid = 1002;
    };
  };

  # Create user
  users.users.gcis = {
    group = "gcis";
    isSystemUser = true;
  };

  # Add user to the libvirtd group
  users.users.gcis.extraGroups = [ "libvirtd" ];

  # Define system packages
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
    win-spice
    gnome.adwaita-icon-theme
  ];

  # Virtualization configuration
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true; # Enable TPM emulation
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
    };
  };

  # Enable SPICE USB redirection
  virtualisation.spiceUSBRedirection.enable = true;

  # Enable the SPICE vdagent service
  services.spice-vdagentd.enable = true;
}
