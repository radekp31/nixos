{
  pkgs,
  lib,
  config,
  ...
}: {
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
