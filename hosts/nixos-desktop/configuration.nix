#Settings for nixos-desktop host
{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./users.nix

    # Common base
    ../common/default.nix
    ../common/profiles/desktop.nix

    # System modules
    ../../modules/system/apps/desktop/kde-plasma6
    ../../modules/system/hardware/gpu/nvidia
    ../../modules/system/apps/nixvim
    ../../modules/system/apps/qmk
    ../../modules/system/apps/qemu
    ../../modules/system/hardware/printers/brother/DCPL2622DW
    ../../modules/system/scripts/fan-control.sh
    ../../modules/system/apps/git
    ../../modules/system/apps/openrgb
    ../../modules/system/hardware/usb
  ];

  #virtualisation.waydroid = {
  #  enable = true;
  #  package = pkgs.waydroid-nftables;
  #};

  #programs.adb.enable = true;

  #programs.appimage.enable = true;
  #programs.appimage.binfmt = true;

  # Override common defaults
  system.autoUpgrade.enable = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  # Host-specific nix settings
  nix.gc = {
    dates = lib.mkForce "daily";
    options = lib.mkForce "--delete-older-than 3d";
  };

  # Host-specific sudo rules
  security.sudo.extraConfig = ''
    Defaults    pwfeedback
    Defaults    insults
    Defaults:radekp timestamp_timeout=30


    user ALL=(ALL) NOPASSWD: ${pkgs.linuxPackages.nvidia_x11.settings}
    radekp ALL=(ALL) NOPASSWD: ${pkgs.rsync}/bin/rsync
  '';

  security.sudo.extraRules = [
    {
      commands = [
        {
          command = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";
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
        {
          command = "${pkgs.gnome-multi-writer}/bin/gnome-multi-writer";
          options = ["NOPASSWD"];
        }
      ];
      groups = ["wheel"];
    }
  ];

  # Hardware-specific boot configuration
  boot.blacklistedKernelModules = ["nouveau"];
  boot.initrd.availableKernelModules = [
    "nvme"
    "vesafb"
    "xhci_pci"
    "usbhid"
  ];

  boot.supportedFilesystems = ["ntfs" "vfat" "ext4" "btrfs"];
  boot.initrd.supportedFilesystems = ["ntfs" "vfat" "ext4" "btrfs"];

  # Bootloader
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    gfxmodeEfi = "1366x768";
    gfxmodeBios = "1366x768";
    theme = null;
    configurationLimit = 15;
    memtest86.enable = true;
  };

  # Kernel
  #boot.kernelPackages = pkgs.linuxPackages_6_17;
  #boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.kernelParams = [
    "boot.shell_on_fail"
    "trace_clock=local"
    "usbcore.autosuspend=-1"
    "usbcore.debug=1"
    "console=tty1"
    "fbcon=map:0"
    "video=DP-2:1920x1080"
    "video=DP-3:off"
    "nvme_core.default_ps_max_latency_us=0"
    "pcie_aspm=off"
    "pcie_port_pm=off"
    "nvme_core.io_timeout=4294967295"
    "nvme_core.max_retries=5"
  ];

  boot.kernelModules = [
    "kvm-amd"
    "kvm-intel"
    "xfs"
  ];

  powerManagement.cpuFreqGovernor = "performance";

  # Networking
  networking.hostName = "nixos-desktop";

  # NVIDIA-specific environment variables
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERM = "xterm-256color";
    NIXOS_CONFIG_LOCATION = "/etc/nixos";
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1";
    XCURSOR_SCALE = "24";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  # Timezone override
  time.timeZone = "Europe/Prague";

  # ASUS motherboard control (hardware-specific)
  services.asusd.enable = true;

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Cockpit
  services.cockpit.enable = true;

  # Hardware-specific packages
  environment.systemPackages = with pkgs; [
    linuxKernel.packages.linux_6_17.asus-ec-sensors
    nvfancontrol
    nvme-cli
    ntfs3g
    libxfs
    #qt6.full
    gnome-multi-writer
  ];

  #networking.networkManager.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Conditionally enable swaylock PAM service if any user has it enabled
  security.pam.services.swaylock = pkgs.lib.mkIf (
    builtins.any (user: user.programs.swaylock.enable or false)
    (builtins.attrValues config.home-manager.users)
  ) {};

  system.stateVersion = "25.05";
}
