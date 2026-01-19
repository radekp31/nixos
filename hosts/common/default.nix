{
  pkgs,
  lib,
  config,
  ...
}: let
  hasNvme = lib.elem "nvme" config.boot.initrd.availableKernelModules;
in {
  # Move tmpfs to RAM on nvme drives and compress it, uses dynamic allocation
  boot.tmp = lib.mkIf hasNvme {
    useTmpfs = true;
    tmpfsSize = "25%";
  };

  zramSwap = lib.mkIf hasNvme {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 15;
  };

  services.udev.extraRules = lib.mkIf hasNvme ''
    # Set scheduler for NVMe to 'none' for maximum throughput
    ACTION=="add|change", KERNEL=="nvme[0-9]n[1-9]", ATTR{queue/scheduler}="none"
  '';

  # Networking
  networking.networkmanager.enable = lib.mkDefault true;
  networking.firewall.enable = true;

  # Locale - use defaults that hosts can override
  time.timeZone = lib.mkDefault "Europe/Prague";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";

  # Security
  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;

  # Nix settings
  system.autoUpgrade = {
    enable = true;
    operation = "boot";
    flake = "git+https://github.com/radekp31/nixos.git#${config.networking.hostName}";
    dates = "02:30";
    randomizedDelaySec = "30min";
    persistent = true;
    allowReboot = false;
  };

  nix = {
    gc = {
      automatic = lib.mkDefault true; # Add mkDefault here too
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 7d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      keep-outputs = true;
      keep-derivations = true;
      min-free = 20 * 1024 * 1024 * 1024; # 20GB
      max-free = 50 * 1024 * 1024 * 1024; # 50GB
    };
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    # Core essentials
    vim
    wget
    curl
    git
    htop
    tree
    tmux
    nh #nix helper
    nix-output-monitor #helper for rebuild debugging
    nix-prefetch-git
    nix-prefetch
    nix-prefetch-scripts
    nix-prefetch-docker
  ];

  # SSH - disabled by default, let hosts opt-in
  services.openssh = {
    enable = lib.mkDefault false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = lib.mkDefault false;
    };
  };

  programs.git = {
    enable = true;
  };
}
