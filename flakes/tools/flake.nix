{
  description = "On-demand tool environments. Heavy toolchains that the system does not need at all times.";

  # WHY THIS FLAKE EXISTS
  #
  # Each shell below holds a toolchain that is large and rarely used. Keeping
  # them in environment.systemPackages or home.packages costs closure size on
  # every generation, even when the tool sits idle for months.
  #
  #   nix develop /etc/nixos/flakes/tools#qmk      # keyboard firmware
  #   nix develop /etc/nixos/flakes/tools#arduino  # Arduino IDE
  #   nix develop /etc/nixos/flakes/tools#vm       # virtual machines
  #
  # Run one command instead of opening a shell:
  #
  #   nix develop /etc/nixos/flakes/tools#arduino -c arduino-ide
  #
  # WHAT STAYS ON THE SYSTEM AND WHY
  #
  # A devShell cannot install udev rules, and it cannot run a daemon. Those two
  # facts decide the split:
  #
  #   - modules/system/apps/qmk keeps hardware.keyboard.qmk.enable, the udev
  #     rule block, and services.udev.packages. A keyboard is only writable
  #     when udev has tagged it, and udev is a system service.
  #   - virtualisation.libvirtd stays a system service. libvirtd requires qemu
  #     directly, so the qemu closure does NOT leave the system while libvirtd
  #     is enabled. The vm shell below is still useful, because it carries
  #     quickemu, the firmware images, and the spice tooling.

  inputs = {
    # Track the same branch as the system flake. Keep the two in step.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            # nrfutil pulls the SEGGER JLink pack, which demands an explicit
            # licence acceptance. hosts/nixos-desktop/configuration.nix sets
            # the same flag for the system.
            segger-jlink.acceptLicense = true;
          };
        };

        # Print the entry banner once. Every shell reuses it.
        banner = name: text: ''
          export DEVSHELL_NAME="${name}"
          echo "${name} environment. ${text}"
        '';
      in {
        # Keyboard firmware. The compiler pair is the weight here:
        # gcc-arm-embedded is 1.07 GiB and avr-gcc is 0.51 GiB.
        # via stays on the system too, because services.udev.packages needs it.
        devShells.qmk = pkgs.mkShell {
          packages = with pkgs; [
            # qmk pulls both cross compilers itself: gcc-arm-embedded at
            # 1.07 GiB and avr-gcc at 0.51 GiB. Do not list them again.
            # avr-gcc is not a top-level attribute in any case.
            qmk
            qmk_hid
            via
            nrfutil
            avrdude
            dfu-util
          ];
          shellHook = banner "qmk" "Run 'qmk setup' first on a new checkout.";
        };

        # Arduino IDE. The IDE bundles its own toolchains at first run.
        devShells.arduino = pkgs.mkShell {
          packages = with pkgs; [
            arduino-ide
            arduino-cli
          ];
          shellHook = banner "arduino" "Run 'arduino-ide' to start the IDE.";
        };

        # Virtual machines. quickemu carries its own qemu.
        # virt-manager is deliberately absent. The user disabled libvirtd on
        # 2026-09-15, so a virt-manager here would find no daemon to reach.
        devShells.vm = pkgs.mkShell {
          packages = with pkgs; [
            quickemu
            quickgui
            qemu_kvm
            virt-viewer
            spice-gtk
            spice-protocol
            swtpm
            OVMF
            virtio-win
          ];
          shellHook = banner "vm" "Run 'quickget' to fetch an image, then 'quickemu'.";
        };

        devShells.default = pkgs.mkShell {
          shellHook = ''
            echo "Pick a shell: #qmk, #arduino, or #vm."
          '';
        };
      }
    );
}
