{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./nvidia-drivers.nix
    ./users.nix
    ../../modules/system/apps/desktop/kde-plasma6/default.nix
    ../../modules/system/apps/nixvim/nixvim.nix
    ../../modules/system/apps/qmk/qmk.nix
    ../../modules/system/apps/qemu/qemu.nix
    ../../modules/system/hardware/printers/brother/DCPL2622DW.nix
    ../../modules/system/scripts/fan-control.sh
    ../../modules/system/apps/git/git.nix
    ../../modules/system/apps/openrgb/openrgb.nix
    ../../modules/system/hardware/usb/usb.nix
  ];

  #System auto upgrades
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };

  # Nix settings
  # - automatic garbage collection
  # - automatic store optimisation
  # - enabling flakes
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true; # Require password for sudo
    extraConfig = ''
      Defaults	pwfeedback
      Defaults	insults

      user ALL=(ALL) NOPASSWD: ${pkgs.linuxPackages.nvidia_x11.settings}
      radekp ALL=(ALL) NOPASSWD: ${pkgs.rsync}/bin/rsync
    '';
    extraRules = [
      {
        commands = [
          {
            command = "${pkgs.linuxPackages.nvidia_x11.settings}";
            options = ["NOPASSWD"];
          }
          {
            command = "${pkgs.linuxPackages.nvidia_x11.bin}";
            options = ["NOPASSWD"];
          }
          {
            command = "${pkgs.systemd}/bin/journalctl";
            options = ["NOPASSWD"];
          }
          {
            command = "${pkgs.util-linux}/bin/dmesg";
            options = ["NOPASSWD"];
          }
        ];
        groups = ["wheel"];
      }
    ];
  };

  # Setup SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  boot.blacklistedKernelModules = ["nouveau"];
  boot.initrd.availableKernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "nvme"
    "vesafb"
    "xhci_pci"
    "usbhid"
  ];
  boot.initrd = {
    enable = true;
  };

  boot.supportedFilesystems = ["ntfs" "vfat" "ext4"];
  boot.initrd.supportedFilesystems = ["ntfs" "vfat" "ext4"];

  # Bootloader.
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  # Grub
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    gfxmodeEfi = "1366x768";
    gfxmodeBios = "1366x768";
    theme = null;
    configurationLimit = 3;
    memtest86.enable = true;
  };

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_6_17;
  boot.kernelParams = [
    "boot.shell_on_fail"
    "trace_clock=local"

    #Disable USB power management
    "usbcore.autosuspend=-1"
    "usbcore.debug=1"
    #Use only 1 screen during boot
    "console=tty1"
    "fbcon=map:0"
    "video=DP-2:1920x1080"
    "video=DP-3:off"

    #Fix for misbehaving nvme drive
    "nvme_core.default_ps_max_latency_us=0"
    "pcie_aspm=off"
    "pcie_port_pm=off"
    "nvme_core.io_timeout=4294967295"
    "nvme_core.max_retries=5"
  ];

  # Enable virtualization # move virtualisations items to qemu.nix
  #virtualisation.libvirtd.enable = true;

  boot.kernelModules = [
    "kvm-amd"
    "kvm-intel"
    #Enable XFS
    "xfs"
  ];

  powerManagement.cpuFreqGovernor = "performance";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.hostName = "nixos-desktop";

  # Environment variables
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERM = lib.mkDefault "xterm-256color";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    NIXOS_CONFIG_LOCATION = "/etc/nixos"; # used for alejandra
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1";
    XCURSOR_SCALE = "24";
    QT_QPA_PLATFORMTHEME = "qt6ct"; # dark mode for Qt apps
  };

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  security.polkit.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  systemd.services.cups = {
    environment = {
      LD_LIBRARY_PATH = lib.mkForce "";
    };
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable dconf
  programs.dconf.enable = true;

  #Set up Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  #Asus motherboard control
  services.asusd.enable = true;

  #Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

  services.cockpit = {
    enable = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #Git and fetchers and other QOL
    git # Good luck without git
    nix-prefetch-git
    nix-prefetch
    nix-prefetch-docker
    nix-prefetch-scripts
    nixos-anywhere

    #Secrets Management
    age
    sops

    #Security scanning
    vulnix
    trivy

    freecad-wayland
    unzip
    pciutils
    wlr-randr
    cmake
    nvme-cli

    #Keyboard utilities
    nrfutil
    qmk
    qmk_hid
    qmk-udev-rules

    # Packages
    dejavu_fonts #keep
    dejavu_fontsEnv
    nixos-icons #keep
    smartmontools #keep
    lm_sensors #keep
    linuxKernel.packages.linux_6_17.asus-ec-sensors
    nvfancontrol
    #libsForQt5 # grub themes
    xdg-utils #keep
    #qt5.full - marked as unsafe, refuses to build
    qt6.full
    ripgrep-all
    termshark
    discord
    arp-scan-rs
    pam
    neofetch # distro stats, deprecated :( - find new one
    curl
    openssh # keep
    htop # system monitor
    fzf # fuzzy finder
    qemu_kvm # virtualisation
    spice-vdagent # copy/paste agent for VMs
    virt-viewer # VM viewer
    tree # dir tree structure viewer
    ntfs3g #Too many windows people around me
    lld_18
    jq
    yt-dlp
    ffmpeg
    tldr
    btop
    nurl # get tarball hashes
    dig
    libxfs
    cockpit

    # Zsh

    zsh # I use zsh btw
    oh-my-zsh # I use fancy zsh btw
    zsh-fzf-tab
    zsh-fzf-history-search
    zsh-autosuggestions
    zsh-syntax-highlighting
    meslo-lgs-nf # font

    # NVIM
    xclip
    wl-clipboard

    # Home manager
    #home-manager

    # Libre Office

    libreoffice-qt # libre office
    hunspell # grammar checking for libre office
    hunspellDicts.en_US-large # enUS dictionary for grammar checking
    hunspellDicts.en_GB-large # enGB dictionary for grammar checking
    hunspellDicts.cs_CZ # csCz dictionary for grammar checking

    # Fonts
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.inconsolata
    nerd-fonts.meslo-lg
    nerd-fonts.space-mono
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-sans
    nerd-fonts.agave
    nerd-fonts.hack
    nerd-fonts.symbols-only
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
