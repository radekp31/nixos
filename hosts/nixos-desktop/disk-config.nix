# The disk layout of nixos-desktop, in plain disko syntax.
#
# This file reproduces the live machine. It is NOT active at runtime:
# hosts/nixos-desktop/configuration.nix sets disko.enableConfig = false, so
# hardware-configuration.nix keeps owning every mount. See that file for the
# reason and for the one flag you flip when you reinstall.
#
# Every key below matches the upstream reference one to one:
#   https://github.com/nix-community/disko/tree/master/example
#
# Reinstall this machine from scratch:
#   lsblk
#   sudo nix run 'github:nix-community/disko/latest#disko-install' -- \
#     --flake '/etc/nixos#nixos-desktop' --disk main /dev/nvme0n1
#
# ONLY the NVMe appears here. The data disks sda and sdb are absent on
# purpose. disko formats what it knows about, so a disk it never sees is a
# disk it can never erase. Both keep their fileSystems entries in
# hardware-configuration.nix.
{lib, ...}: {
  disko.devices.disk.main = {
    type = "disk";
    # disko-install --disk main /dev/… overrides this at install time.
    device = lib.mkDefault "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          size = "5G";
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
            # Overwrite an existing filesystem on the partition.
            extraArgs = ["-f"];

            # The top level of the volume, which holds the subvolumes
            # themselves. The live system mounts it with subvolid=5.
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
}
