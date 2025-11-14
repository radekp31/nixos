## Target structure
nixos/<br>
├── flake.nix<br>
├── hosts/<br>
│   ├── nixos-desktop/<br>
│   │   ├── default.nix<br>
│   │   ├── hardware-configuration.nix<br>
│   │   └── home.nix<br>
│   ├── generic-server/<br>
│   │   ├── default.nix<br>
│   │   └── hardware-configuration.nix<br>
│   ├── dt-wsl-nix/<br>
│   │   ├── default.nix<br>
│   │   └── home.nix<br>
│   └── hyperv/<br>
│       ├── default.nix<br>
│       └── hardware-configuration.nix<br>
│<br>
├── modules/<br>
│   ├── system/<br>
│   │   ├── boot/<br>
│   │   │   └── default.nix<br>
│   │   ├── hardware/<br>
│   │   │   ├── openrgb.nix<br>
│   │   │   ├── qemu.nix<br>
│   │   │   └── vbox.nix<br>
│   │   ├── drivers/<br>
│   │   │   └── brother.nix<br>
│   │   ├── networking/<br>
│   │   │   └── default.nix<br>
│   │   ├── security/<br>
│   │   │   ├── sops.nix<br>
│   │   │   └── default.nix<br>
│   │   ├── server/<br>
│   │   │   ├── webserver.nix<br>
│   │   │   └── default.nix<br>
│   │   ├── usb/<br>
│   │   │   └── default.nix<br>
│   │   └── desktop/<br>
│   │       ├── hyprland.nix<br>
│   │       └── default.nix<br>
│   │<br>
│   └── home/<br>
│       ├── programs/<br>
│       │   ├── git.nix<br>
│       │   ├── nixvim/<br>
│       │   │   └── default.nix<br>
│       │   ├── shells/<br>
│       │   │   └── zsh.nix<br>
│       │   └── treefmt.nix<br>
│       ├── desktop/<br>
│       │   ├── window-managers/<br>
│       │   │   ├── hyprland.nix<br>
│       │   │   ├── bspwm.nix<br>
│       │   │   └── niri.nix<br>
│       │   ├── lock-screens/<br>
│       │   │   └── hyprlock.nix<br>
│       │   ├── bars/<br>
│       │   │   └── waybar.nix<br>
│       │   ├── launchers/<br>
│       │   │   └── rofi.nix<br>
│       │   └── widgets/<br>
│       │       ├── eww.nix<br>
│       │       └── glance.nix<br>
│       └── scripts/<br>
│           └── default.nix<br>
│<br>
├── home/<br>
│   └── radekp/<br>
│       ├── default.nix<br>
│       ├── packages.nix<br>
│       ├── desktop.nix<br>
│       └── work.nix<br>
│<br>
├── deployments/<br>
│   └── server/<br>
│       └── generic/<br>
│<br>
├── colors/<br>
├── wallpapers/<br>
└── secrets/<br>
