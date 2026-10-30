# One disk, btrfs root with subvolumes, boots on both BIOS and UEFI.
#
# Pick this when you want snapshots or compression. The subvolume names match
# nixos-desktop, so a snapshot tool configured for one machine fits the other.
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
            type = "btrfs";
            # Overwrite an existing filesystem on the partition.
            extraArgs = ["-f"];

            # The top level of the volume. Mount it to manage snapshots.
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
