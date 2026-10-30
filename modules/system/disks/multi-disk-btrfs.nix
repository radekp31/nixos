# Two disks: a btrfs system disk, plus a second disk for bulk data.
#
# >>> THIS TEMPLATE DESTROYS BOTH DISKS. <<<
#
# Read that line again before you use it. A disk listed here is a disk disko
# formats. If the second disk already holds data you want, do NOT add it to
# this file. Mount it with a plain fileSystems entry instead, the way
# hosts/nixos-desktop/hardware-configuration.nix mounts /media/WDRED. A disk
# disko never sees is a disk disko can never erase.
#
# Usage: copy this file into hosts/<host>/, import it, and edit both devices.
#   lsblk
#   sudo nix run 'github:nix-community/disko/latest#disko-install' -- \
#     --flake '/etc/nixos#<host>' --disk main /dev/sda --disk data /dev/sdb
#
# Use grub with this layout, because of the BIOS slot:
#   boot.loader.grub.enable = true;
#   boot.loader.grub.efiSupport = true;
#   boot.loader.grub.efiInstallAsRemovable = true;
{lib, ...}: {
  disko.devices.disk = {
    # The system disk.
    main = {
      type = "disk";
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
              type = "btrfs";
              extraArgs = ["-f"];
              mountpoint = "/mnt/btr_pool";
              mountOptions = ["noatime"];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = ["compress=zstd" "noatime" "flushoncommit"];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime" "flushoncommit"];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = ["compress=zstd" "noatime" "flushoncommit"];
                };
              };
            };
          };
        };
      };
    };

    # The data disk. One partition across the whole device.
    data = {
      type = "disk";
      device = lib.mkDefault "/dev/sdb";
      content = {
        type = "gpt";
        partitions.data = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/data";
            # nofail lets the machine boot when this disk is absent.
            mountOptions = ["defaults" "noatime" "nofail"];
          };
        };
      };
    };
  };
}
