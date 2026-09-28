# Prove every disk layout in the repository before a disk depends on it.
#
# A layout in modules/system/disks/ is imported by no host, because two layouts
# in one host collide. Without this file they would be never-evaluated code.
#
# Two levels of proof:
#
#   checks.disko-<name>        builds the real partition script. Cheap, so
#                              `nix flake check` runs it on every push.
#   packages.disko-test-<name> boots a VM, runs the layout against a blank
#                              disk, installs NixOS and reboots into it. This
#                              is the only proof that a fresh install works.
#
# The tests are packages and NOT checks on purpose. `nix flake check` BUILDS
# every check, and a VM test builds a whole system closure. A full closure can
# exhaust a free CI runner, so these stay on demand:
#
#   nix build '.#disko-test-single-disk-btrfs'
#   nix build --no-link --print-out-paths '.#checks.x86_64-linux.disko-single-disk-btrfs'
{inputs, ...}: {
  perSystem = {system, ...}: let
    inherit (inputs.nixpkgs) lib;

    layoutDir = ../modules/system/disks;

    # Every .nix file in the layout directory is a layout. The README is not.
    layoutNames =
      lib.filter (lib.hasSuffix ".nix")
      (lib.attrNames (builtins.readDir layoutDir));

    # A layout on its own is not a system. Give it the least a NixOS
    # evaluation needs, and nothing more.
    testSystem = layout:
      lib.nixosSystem {
        modules = [
          inputs.disko.nixosModules.disko
          layout
          {
            nixpkgs.hostPlatform = system;
            system.stateVersion = "26.05";
          }
        ];
      };

    libraryLayouts =
      map (file: {
        name = lib.removeSuffix ".nix" file;
        layout = layoutDir + "/${file}";
      })
      layoutNames;

    # The live desktop layout reproduces a real machine, so a break here
    # matters more than a break in a template. It takes a script check only.
    # Upstream hardcodes 4096 MiB test disks in lib/tests.nix, this layout
    # takes a 5G ESP, and that size is not reachable from here.
    scriptLayouts =
      libraryLayouts
      ++ [
        {
          name = "nixos-desktop";
          layout = ../hosts/nixos-desktop/disk-config.nix;
        }
      ];

    build = attr: prefix: entries:
      lib.listToAttrs (
        map (
          e:
            lib.nameValuePair "${prefix}${e.name}"
            (testSystem e.layout).config.system.build.${attr}
        )
        entries
      );
  in {
    checks = build "diskoScript" "disko-" scriptLayouts;
    packages = build "installTest" "disko-test-" libraryLayouts;
  };
}
