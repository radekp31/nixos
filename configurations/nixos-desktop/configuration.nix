{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./nvidia-drivers.nix
    ../../modules/default.nix
    ../../modules/apps/nixvim/nixvim.nix
    ../../modules/apps/qmk/qmk.nix
    ../../modules/apps/qemu/qemu.nix
    ../../drivers/brother/DCPL2622DW.nix
  ];

  nixpkgs.config.segger-jlink.acceptLicense = true; #clean

  # Configure Nixpkgs to use the unstable channel for system-wide packages
  nixpkgs.config = {
    allowUnfree = true;
    channels = {
      enable = true;

      urls = ["https://nixos.org/channels/nixpkgs-unstable"];
    };
    packageOverrides = pkgs: {
      unstable = import <nixos-unstable> {config = pkgs.config;};
    };
    overlays = [
      (import (
        builtins.fetchTarball {
          url = "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
          sha2656 = "wJQCxyMRc4P26zDrHmZiRD5bbfcJpqPG3e2djdGG3pk=";
        }
      ))
    ];
  };

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
      dates = "weekly";
      options = "--delete-older-than 5d";
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
      user ALL=(ALL) NOPASSWD: ${pkgs.linuxPackages.nvidia_x11.settings}
    '';
    extraRules = [
      {
        commands = [
          {
            command = "${pkgs.linuxPackages.nvidia_x11.settings}"; #remove?
            options = ["NOPASSWD"];
          }
          {
            command = "${pkgs.linuxPackages.nvidia_x11.bin}"; #remove?
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
    services = {
      lvm = {
        enable = false;
      };
    };
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
    #theme = "${pkgs.libsForQt5.breeze-grub}/grub/themes/breeze";
    theme = null;
  };

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_6_16;
  boot.kernelParams = [
    "boot.shell_on_fail"
    "tsc=unstable"
    "trace_clock=local"

    #Disable USB power management
    "usbcore.autosuspend=-1"
    "usbcore.debug=1"
    #Use only 1 screen during boot
    "console=tty1"
    "fbcon=map:0"
    "video=DP-2:1920x1080"
    "video=DP-3:off"
  ];

  # Enable virtualization # move virtualisations items to qemu.nix
  #virtualisation.libvirtd.enable = true;
  boot.kernelModules = [
    "kvm-amd"
    "kvm-intel"
  ];

  powerManagement.cpuFreqGovernor = "performance";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.hostName = "nixos-desktop";

  # Session variables
  environment.sessionVariables = {
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

  # Environment variables
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERM = lib.mkDefault "xterm-256color";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
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

  services.flatpak = {
    enable = true;
    package = pkgs.flatpak;
  };

  security.polkit.enable = true; # polkit
  services.gnome.gnome-keyring.enable = true; # secret service
  security.pam.services.swaylock = {};

  #Enable Android Debug Bridge
  programs.adb.enable = true;

  #Desktop settings
  programs.niri = {
    enable = true;
  };

  services.desktopManager.plasma6.enable = false;
  services.displayManager = {
    defaultSession = "niri";
    gdm.wayland.enable = true;
    sddm = {
      autoNumlock = true;
      enable = true;
      package = lib.mkForce pkgs.kdePackages.sddm; # leave default?
      theme = "catppuccin-mocha";
      wayland.enable = true;
    };
  };

  xdg.portal = {
    enable = true;
  };

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.radekp = {
    isNormalUser = true;
    description = "Radek Polasek";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];
    packages = with pkgs; [
      #  thunderbird
    ];
  };

  users.users.sddm.extraGroups = ["video"];

  # Enable dconf
  programs.dconf.enable = true;

  #Set up Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
    ];

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  #Set up ZSH - clean
  users.defaultUserShell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    promptInit = ''
      # Enable direnv
      eval "$(direnv hook zsh)"

      # Add new line on each prompt
      precmd() { echo }
    '';
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellInit = ''
      # Enable fzf plugin
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    '';

    shellAliases = {
      update = "sudo nixos-rebuild switch";
      edit = "sudoedit /etc/nixos/configuration.nix";
      update-vm = "sudo nixos-rebuild switch build-vm && dunstify \"NixOS Rebuild\" \"VM is ready.\"";
      rebuild = "sudo nixos-rebuild test && dunstify \"NixOS Rebuild\" \"Test rebuild is done.\"";
      rebuild-switch = "sudo nixos-rebuild switch && dunstify \"NixOS Rebuild\"\"Switch rebuild is done.\"";
      manix = ''
        manix "" | grep '^# ' | sed 's/^# \\(.*\\) (.*/\\1/;s/ (.*//;s/^# //' | fzf --preview="manix '{}'" | xargs manix
      '';
      ll = "ls -lahg";
      lld = "ls -lahgd";
      man = "tldr";
      cat = "bat -pp";
      nix-push-config = "alejandra $NIXOS_CONFIG_LOCATION && git fetch --all && git add . && git commit -m \"update on $(date '+%Y-%m-%d %H:%M:%S')\" && git push";
      lg1 = "git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
      lg2 = "git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(auto)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)'";
      lg = "lg1";
    };

    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "fzf"
      ];
      theme = "gnzh";
    };
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
    openvas-scanner
    gvm-libs
    gvm-tools
    ospd-openvas

    #Security scanning
    vulnix
    trivy

    # TEST
    #move keyboard app to qmk.nix
    #freecad-wayland
    udiskie #remove
    unzip #remove
    p7zip #remove
    pciutils #what is this?
    unetbootin #clean?
    wlr-randr #clean?

    #Keyboard utilities
    nrfutil #clean?
    qmk #clean?
    qmk_hid #clean
    qmk-udev-rules #clean

    (catppuccin-sddm.override {
      flavor = "mocha";
      font = "Noto Sans";
      fontSize = "9";
      background = "${pkgs.catppuccin-sddm}/wallpaper.png";
      loginBackground = true;
    })

    # Wayland + Hyprland # clean/remove
    xwayland-satellite
    wayland-utils
    wayland-protocols
    pam
    hyprland #remove?
    dunst #remove?
    slurp #keep
    xdg-desktop-portal-hyprland #remove?

    # Packages
    dejavu_fonts #keep
    dejavu_fontsEnv
    nixos-icons #keep
    smartmontools #keep
    lm_sensors #keep
    #libsForQt5 # grub themes
    xdg-utils #keep
    qt5.full
    qt6.full
    ripgrep-all
    termshark
    discord
    arp-scan-rs
    neofetch # distro stats, deprecated :( - find new one
    manix # nix options manual
    curl
    openssh # keep
    htop # system monitor
    fzf # fuzzy finder
    plymouth # boot customization
    qemu_kvm # virtualisation
    spice-vdagent # copy/paste agent for VMs
    virt-viewer # VM viewer
    tree # dir tree structure viewer
    rofi # awesome launch menu
    rofi-power-menu # awesome power menu
    ntfs3g #Too many windows people around me
    shutter # snipping tool
    dunst # notification tool
    lld_18
    jq
    yt-dlp
    ffmpeg
    tldr
    btop
    nurl # get tarball hashes

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
    home-manager

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
  system.stateVersion = "25.11"; # Did you read the comment?
}
