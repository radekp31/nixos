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
    # Disabled 2026-09-15 by user decision. Re-enable with this line uncommented.
    #../../modules/system/apps/waydroid
    ../../modules/system/apps/btrfs
    ../../modules/system/hardware/gpu/nvidia
    ../../modules/system/apps/nixvim
    ../../modules/system/apps/qmk
    ../../modules/system/apps/qemu
    #../../modules/system/hardware/printers/brother/DCPL2622DW
    ../../modules/system/hardware/usb
    ../../modules/system/apps/desktop/kde-plasma6
    ../../modules/system/apps/nix-ld
    ../../modules/system/apps/steam
    ../../modules/system/hardware/bluetooth
    # Deferred 2026-09-15 by user decision. The module is finished and
    # verified. Uncomment this line to install the secrets again.
    #../../modules/system/secrets/sops
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
  services.udev.packages = [pkgs.arduino-core];

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
  boot.blacklistedKernelModules = ["nouveau" "fjes"];
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
  #boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.kernelPackages = pkgs.linuxPackages_7_2;
  boot.kernelParams = [
    "boot.shell_on_fail"
    "trace_clock=local"
    # usbcore.autosuspend=-1 comes from modules/system/hardware/bluetooth.
    "console=tty1"
    "fbcon=map:0"
    "video=DP-2:1920x1080"
    "video=DP-3:off"
    "nvme_core.io_timeout=30"
    "nvme_core.max_retries=5"
    "acpi_enforce_resources=lax"
    "pcie_ports=native"
  ];

  boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 1;
  boot.kernel.sysctl."kernel.sysrq" = 1;

  boot.kernelModules = [
    # kvm-amd comes from modules/system/apps/qemu.
    "xfs" # /media/A400, see hardware-configuration.nix
    "nct6775"
  ];

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
  };

  powerManagement.cpuFreqGovernor = "performance";

  # Networking
  networking.hostName = "nixos-desktop";

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXOS_CONFIG_LOCATION = "/etc/nixos";

    # NVIDIA driver selection. These stay global on purpose: they steer
    # libglvnd, GBM, and VA-API for every client. Keep them under review.
    # Remove one at a time and test Firefox, video playback, and Steam.
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  environment.sessionVariables = {
    # Electron and Chromium applications run on Wayland.
    NIXOS_OZONE_WL = "1";
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

  #virtualisation.docker.enable = true;

  networking.firewall = {
    enable = true;
    # 2026-09-15: 22 is the only port with a listener. Nothing served 5432
    # (postgres) or 5050 (pgadmin), and neither is declared anywhere in this
    # repository. DNS and NTP replies reach a client through conntrack, so
    # inbound UDP 53 and 123 were never needed either.
    allowedTCPPorts = [22];
  };

  # Hardware-specific packages
  environment.systemPackages = with pkgs; [
    alejandra
    #linuxKernel.packages.linux_6_18.asus-ec-sensors
    linuxKernel.packages.linux_7_2.asus-ec-sensors
    nvfancontrol
    nvme-cli
    ntfs3g
    libxfs
    docker-compose
  ];

  #networking.networkManager.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Conditionally enable swaylock PAM service if any user has it enabled
  security.pam.services.swaylock = pkgs.lib.mkIf (
    builtins.any (user: user.programs.swaylock.enable or false)
    (builtins.attrValues config.home-manager.users)
  ) {};

  system.stateVersion = "25.05";
}
