# One disk, LUKS full disk encryption, btrfs root with subvolumes. UEFI only.
#
# /boot stays unencrypted, because the firmware must read it. Everything else
# sits inside the LUKS container.
#
# This template holds NO key material. disko therefore asks for the passphrase
# at install time, and the initrd asks for it at every boot. That is the
# askPassword default: it turns itself on when no keyFile and no passwordFile
# are set. Never commit a key file to this repository.
#
# UEFI only. grub plus LUKS is awkward, so this layout drops the
# BIOS slot and uses systemd-boot:
#   boot.loader.systemd-boot.enable = true;
#   boot.loader.efi.canTouchEfiVariables = true;
#
# Usage: copy this file into hosts/<host>/, import it, and edit the device.
#   lsblk
#   sudo nix run 'github:nix-community/disko/latest#disko-install' -- \
#     --flake '/etc/nixos#<host>' --disk main /dev/nvme0n1
#
# `nix build '.#disko-test-encrypted-btrfs'` is expected to FAIL as written.
# A VM test runs unattended, and this
# layout stops to ask for a passphrase. Upstream solves it in its own example
# with `settings.keyFile = "/tmp/secret.key"`, a file the test harness writes.
# Add that line to a COPY when you want to test, never to this file.
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
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };

        luks = {
          size = "100%";
          content = {
            type = "luks";
            # The name of the unlocked device under /dev/mapper.
            name = "crypted";

            settings = {
              # Pass TRIM through to the SSD. This tells an attacker which
              # blocks are unused. Set it to false if that matters to you.
              allowDiscards = true;
            };

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
  };
}
