{
  pkgs,
  ...
}: {
  # User grub instead
  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # Locale
  time.timeZone = "Europe/Prague";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # Security
  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;

  # Nix settings
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

  # System auto upgrades
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    flake = "/etc/nixos";
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    tree
  ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "24.05";
}
