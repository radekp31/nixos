# NixOS Configuration Roadmap

2026-11-05
### Proposed new structure to increase flake input loading and improve overall structure

.
├── flake.lock
├── flake.nix
├── treefmt.nix
├── assets/                 # Centralized assets (wallpapers & patches)
│   ├── patches/            # Moved from root patches/ & modules/system/...
│   └── wallpapers/         # Moved from extra/wallpapers/ & KDE modules
├── scripts/                # Utility scripts (e.g., dead-code-scan.py from extra/)
├── hosts/                  # STRICTLY machine definitions (no shared code)
│   ├── nixos-desktop/      # configuration.nix, hardware-configuration.nix, disk-config.nix, users.nix, variables.nix
│   ├── nixos-wsl/          # configuration.nix, hardware-configuration.nix, devbox.nix, users.nix, variables.nix
│   ├── desktop-minimal/    # configuration.nix
│   ├── hyperv/             # configuration.nix, users.nix
│   └── server-generic/     # configuration.nix, hardware-configuration.nix, users.nix (consolidated from server/generic & deployments/)
├── modules/                # All reusable building blocks
│   ├── home/               # Home Manager profiles, apps (alacritty, foot, tmux, wezterm), colorschemes, user radekp/
│   ├── system/             # System-level modules (reorganized by category)
│   │   ├── base/           # Core system settings, Lix, locale, nix-ld
│   │   ├── desktop/        # KDE Plasma, GNOME, XFCE, tuigreet, sysc-greet
│   │   ├── hardware/       # GPU (nvidia), bluetooth, printers (Brother), USB
│   │   ├── services/       # K8s, webserver, cockpit
│   │   ├── storage/        # Btrfs tools & disko templates (moved from disks/)
│   │   └── virtualization/ # QEMU, Waydroid, Steam
│   └── devShells/          # Dev environments (azure, devops, nix, python, rust)
└── parts/                  # flake-parts files (hosts.nix, disks.nix, formatting.nix, shells.nix)

Key migration notes from current layout:

    Purged hosts/common/: Absorbed entirely into modules/system/base/ and categorical subfolders so your hosts only import functional system capabilities.

    Cleaned Assets: Wallpapers scattered inside KDE module folders and patch files are now centralized under assets/.
