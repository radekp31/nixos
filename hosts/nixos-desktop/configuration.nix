#Settings for nixos-desktop host
{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ./variables.nix

    # The disk layout of this machine. It is inert at runtime; see the
    # disko.enableConfig note below.
    inputs.disko.nixosModules.disko
    ./disk-config.nix

    # Common base
    ../common/default.nix
    ../common/profiles/desktop.nix

    # System modules
    ../../modules/system/apps/btrfs
    # claude-code comes from nixpkgs_unstable, not from the release input.
    ../../modules/system/apps/claude-code
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
    #../../modules/system/secrets/sops
  ];

  # disko builds the partition script and sets NOTHING else. The flag gates
  # exactly fileSystems, boot and swapDevices in the upstream module, so
  # hardware-configuration.nix keeps owning every mount and this machine boots
  # as it always has.
  #
  # Set it to true ONLY when you reinstall from ./disk-config.nix. The layout
  # mounts by partition label, and the disk in this machine carries no disko
  # labels today, so flipping the flag on the running system breaks the boot.
  disko.enableConfig = false;

  # There is no VM install test for THIS layout. Two upstream facts block it:
  #   1. lib/tests.nix hardcodes 4096 MiB test disks. The ESP below is 5G, so
  #      sgdisk fails with "Error encountered; not saving changes".
  #   2. The harness sets boot.loader.grub.efiInstallAsRemovable, which NixOS
  #      forbids together with the canTouchEfiVariables this host needs.
  # The 5G ESP is correct: 15 generations plus memtest86 do not fit in 1G.
  # `nix build '.#disko-test-single-disk-btrfs'` covers the same GPT, btrfs and
  # subvolume machinery on a 1G ESP.

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
    Defaults:${config.my.user.name} timestamp_timeout=30

    ${config.my.user.name} ALL=(ALL) NOPASSWD: ${pkgs.rsync}/bin/rsync
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
  # asus_wmi_sensors reads the IT8665E through BIOS WMI calls, the same chip
  # that it87 drives (see below). Remove it to decrease the concurrent access.
  # asus_ec_sensors reads the embedded controller, so it stays.
  boot.blacklistedKernelModules = ["nouveau" "fjes" "asus_wmi_sensors"];
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
    # CONFIG_DAMON_STAT_ENABLED_DEFAULT starts kdamond, which costs about 10%
    # of one core and raises the idle CPU temperature. Nothing reads its
    # statistics.
    "damon_stat.enabled=0"
    "pcie_ports=native"
  ];

  boot.kernel.sysctl."kernel.unprivileged_userns_clone" = 1;
  boot.kernel.sysctl."kernel.sysrq" = 1;

  boot.kernelModules = [
    # kvm-amd comes from modules/system/apps/qemu.
    "xfs" # /media/A400, see hardware-configuration.nix
    # The Super I/O chip is an ITE IT8665E at 0x290. The kernel has no driver
    # for it. The out-of-tree it87 fork below gives the pwm files that
    # CoolerControl needs.
    "it87"
  ];

  boot.extraModulePackages = [config.boot.kernelPackages.it87];
  # ACPI claims port 0x290, so it87 refuses to bind without this flag. The
  # flag is risky: BIOS ACPI code and it87 can access the chip at the same
  # time. The it87 README warns of races and unexpected reboots.
  boot.extraModprobeConfig = ''
    options it87 ignore_resource_conflict=1
  '';

  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
  };

  # Do not set powerManagement.cpuFreqGovernor here. The amd-pstate-epp
  # driver defaults to the powersave governor, which suits this CPU. A
  # performance setting raises boost aggression on the Ryzen 5800X. That
  # increases the Tctl spikes which drive the BIOS fan curve.

  # Networking
  networking.hostName = "nixos-desktop";

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXOS_CONFIG_LOCATION = "/etc/nixos";

    # NVIDIA driver selection. Global, because they steer libglvnd, GBM, and
    # VA-API for every client.
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

  virtualisation.docker.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22];
  };

  # Hardware-specific packages
  environment.systemPackages = with pkgs; [
    alejandra
    nvfancontrol
    nvme-cli
    ntfs3g
    libxfs
    docker-compose
    docker
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
