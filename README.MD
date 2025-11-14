# Target Repository Structure

├── flake.nix
├── modules/
│   ├── base.nix
│   ├── boot.nix
│   └── ...
├── hosts/
│   ├── desktop/
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   ├── server/
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   └── nixos-wsl/
│       └── configuration.nix
└── home/
├── radekp/
│   ├── home.nix
│   ├── packages.nix
│   └── programs/
│       ├── git.nix
│       ├── zsh.nix
│       └── ...
└── common.nix


