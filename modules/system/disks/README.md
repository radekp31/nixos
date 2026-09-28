# Disk layouts

Ready [disko](https://github.com/nix-community/disko) layouts for a fresh
install. Each file is plain disko syntax, so the upstream
[reference](https://github.com/nix-community/disko/tree/master/example)
and the [documentation](https://github.com/nix-community/disko/tree/master/docs)
describe your file directly. There is no wrapper and no translation layer.

## The layouts

| File                    | Root                    | Boots         | Use it when                       |
| ----------------------- | ----------------------- | ------------- | --------------------------------- |
| `single-disk-ext4.nix`  | ext4                    | BIOS and UEFI | you want the simple, safe default |
| `single-disk-btrfs.nix` | btrfs with subvolumes   | BIOS and UEFI | you want snapshots or compression |
| `multi-disk-btrfs.nix`  | btrfs, plus a data disk | BIOS and UEFI | a second disk holds bulk data     |
| `encrypted-btrfs.nix`   | LUKS, then btrfs        | UEFI only     | the machine leaves the house      |

`hosts/nixos-desktop/disk-config.nix` is a fifth layout. It is not in this
table, because it reproduces one real machine instead of serving as a start
point. Read it as a worked example.

None of these files is imported anywhere by default. Two layouts in one host
would collide. Copy the one you want.

## Install a new machine

1. Boot the NixOS installer and find the disk.

   ```console
   lsblk
   ```

2. Copy the layout into the new host directory and set the device.

   ```console
   cp modules/system/disks/single-disk-btrfs.nix hosts/<host>/disk-config.nix
   ```

3. Import it, together with the disko module, in `hosts/<host>/configuration.nix`.

   ```nix
   {inputs, ...}: {
     imports = [
       inputs.disko.nixosModules.disko
       ./disk-config.nix
     ];
   }
   ```

4. Set the bootloader the layout asks for. Each file names it in the header.

5. Partition, format and install in one command. `--disk main /dev/…`
   overrides the device in the file, so the committed value never has to be
   correct for the machine in front of you.

   ```console
   sudo nix run 'github:nix-community/disko/latest#disko-install' -- \
     --flake '/etc/nixos#<host>' --disk main /dev/nvme0n1
   ```

The hardware scan is still needed, for drivers rather than for disks. Run it
with `--no-filesystems`, because the layout owns the mounts:

```console
nixos-generate-config --no-filesystems --root /mnt
```

## Data disks

**disko formats every disk it knows about.** A disk that already holds data
you want must stay out of `disko.devices`. Mount it with a plain `fileSystems`
entry instead, as `hosts/nixos-desktop/hardware-configuration.nix` mounts
`/media/WDRED`. A disk disko never sees is a disk disko can never erase.

## Something more exotic

Upstream ships 39 layouts, including ZFS, mdadm RAID, LVM, bcachefs and FIDO2
unlock. Copy the closest one and edit it:
<https://github.com/nix-community/disko/tree/master/example>

## Checks

Two levels, both defined in `parts/disks.nix`.

**The partition script, on every push.** `nix flake check` builds the real
script for every layout here, so a broken layout fails in CI rather than on an
installer prompt. Read a script before you trust it with a disk:

```console
nix build --no-link --print-out-paths \
  '.#checks.x86_64-linux.disko-single-disk-btrfs'
```

**The full install, on demand.** Each layout also has a VM test. It boots a
virtual machine, runs the layout against a blank disk, installs NixOS on the
result and reboots into it. Run it before you use a layout on hardware you
care about:

```console
nix build '.#disko-test-single-disk-btrfs'
```

These are packages and not checks on purpose. `nix flake check` builds every
check, and a VM test builds a whole system closure, which can exhaust a free
CI runner.

`hosts/nixos-desktop/disk-config.nix` has a script check but no VM test.
Upstream hardcodes 4096 MiB test disks in `lib/tests.nix`, that layout takes a
5G ESP, and the size is not reachable from our configuration. Every layout in
this directory uses a 1G ESP and fits.
