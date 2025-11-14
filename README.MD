## Target Repository Structure

├── flake.nix<br>
├── modules/<br>
│   ├── base.nix<br>
│   ├── boot.nix<br>
│   └── ...<br>
├── hosts/<br>
│   ├── desktop/<br>
│   │   ├── configuration.nix<br>
│   │   └── hardware-configuration.nix<br>
│   ├── server/<br>
│   │   ├── configuration.nix<br>
│   │   └── hardware-configuration.nix<br>
│   └── nixos-wsl/<br>
│       └── configuration.nix<br>
└── home/<br>
    ├── radekp/<br>
    │   ├── home.nix<br>
    │   ├── packages.nix<br>
    │   └── programs/<br>
    │       ├── git.nix<br>
    │       ├── zsh.nix<br>
    │       └── ...<br>
    └── common.nix

