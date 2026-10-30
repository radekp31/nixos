# One disk, ext4 root, boots on both BIOS and UEFI.
#
# The safe default. Pick this when you do not know which layout you want.
# The 1M EF02 slot makes the disk bootable on a BIOS machine as well, and it
# costs nothing on a UEFI machine.
#
# Usage: copy this file into hosts/<host>/, import it, and edit the device.
#   lsblk
#   sudo nix run 'github:nix-community/disko/latest#disko-install' -- \
#     --flake '/etc/nixos#<host>' --disk main /dev/sda
#
# Use grub with this layout, because of the BIOS slot:
#   boot.loader.grub.enable = true;
#   boot.loader.grub.efiSupport = true;
#   boot.loader.grub.efiInstallAsRemovable = true;
{lib, ...}: {
  disko.devices.disk.main = {
    type = "disk";
    # disko-install --disk main /dev/… overrides this at install time.
    device = lib.mkDefault "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        # The BIOS boot partition. grub writes its second stage here.
        boot = {
          priority = 1;
          size = "1M";
          type = "EF02";
        };

        ESP = {
          priority = 2;
          name = "ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };

        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
