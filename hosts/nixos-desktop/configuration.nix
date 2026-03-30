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
    ./variables.nix

    # Common base
    ../common/default.nix
    ../common/profiles/desktop.nix

    # System modules
    ../../modules/system/apps/waydroid
    ../../modules/system/apps/btrfs
    ../../modules/system/hardware/gpu/nvidia
    ../../modules/system/apps/nixvim
    ../../modules/system/apps/qmk
    ../../modules/system/apps/qemu
    ../../modules/system/hardware/printers/brother/DCPL2622DW
    ../../modules/system/hardware/usb
    ../../modules/system/hardware/sound/pipewire
    ../../modules/system/apps/desktop/kde-plasma6
    ../../modules/system/apps/nix-ld
    ../../modules/system/apps/steam
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.nvidia.acceptLicense = true;
  nixpkgs.config.segger-jlink.acceptLicense = true;

  users.groups.adbusers = {};
  users.groups.plugdev = {};

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", MODE="0666", GROUP="plugdev"
    # Rockchip Maskrom mode
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="350b", MODE="0660", GROUP="adbusers"
    # Rockchip Loader mode
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", ATTR{idProduct}=="350a", MODE="0660", GROUP="adbusers"
    # General Rockchip device rules
    SUBSYSTEM=="usb", ATTR{idVendor}=="2207", MODE="0660", GROUP="adbusers"
  '';

  # Override common defaults
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  # Host-specific nix settings
  nix.gc = {
    dates = lib.mkForce "weekly";
    options = lib.mkForce "--delete-older-than 14d";
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
  boot.blacklistedKernelModules = ["nouveau" "fjes" "kvm_intel"];
  boot.extraModulePackages = [config.boot.kernelPackages.it87]; # CPU fan goes full rpm due to missing driver
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
    #"pcie_port_pm=off"
    "nvme_core.io_timeout=30"
    "nvme_core.max_retries=5"
    # Disable nvme power saving
    #"pcie_aspm=off"
    #"nvme_core.default_ps_max_latency_us=0"
    # CPU cooler driver setup
    "acpi_enforce_resources=lax"
    "pcie_ports=native"

  ];

  boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 1;
  boot.kernel.sysctl."kernel.sysrq" = 1;


  boot.kernelModules = [
    "kvm-amd"
    "kvm-intel"
    "xfs"
    "nct6775"
  ];

  services.logind.settings.Login = { HandlePowerKey = "ignore"; HandleSuspendKey = "ignore"; HandleHibernateKey = "ignore";};

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

  # Fix NVIDIA + Wayland + Steam know decorations not drawn issue
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    __GL_THREADED_OPTIMIZATIONS = "0";
    DXVK_ASYNC = "1";
  };

  # Timezone override
  time.timeZone = "Europe/Prague";

  # ASUS motherboard control (hardware-specific)
  #services.asusd.enable = true;

  

  #nixpkgs.config.allowUnfreePredicate = pkg:
  #  builtins.elem (lib.getName pkg) [
  #    "steam"
  #    "steam-unwrapped"
  #  ];

  # Cockpit
  #services.cockpit.enable = true;

  virtualisation.docker.enable = true;

    networking.firewall = {
    enable = true;
    allowedTCPPorts = [22 5432 5050]; 
    allowedUDPPorts = [53 123 5432 5050];
  };

  # Hardware-specific packages
  environment.systemPackages = with pkgs; [
    alejandra
    linuxKernel.packages.linux_6_18.asus-ec-sensors
    nvfancontrol
    nvme-cli
    ntfs3g
    libxfs
    docker-compose

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
