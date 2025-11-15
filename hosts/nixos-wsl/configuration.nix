# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{
  config,
  lib,
  ...
}: let
  isWSL = builtins.pathExists /proc/sys/fs/binfmt_misc/WSLInterop;
in {
  imports = [
    ./system-packages.nix
    ./users.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "nixos"; #radekp?

  # Networking
  networking.networkmanager.enable = lib.mkIf (!isWSL) true;
  networking.useDHCP = false;

  # Timezone and locale
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Nix settings (universal)
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Security
  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = lib.mkIf (!isWSL) true;

  # Firewall
  networking.firewall.enable = true;

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Universal packages
  #environment.systemPackages = with pkgs; [
  #  vim
  #  wget
  #  curl
  #  git
  #  htop
  #  tmux
  #];

  environment.variables = {
    EDITOR = "nvim";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  system.stateVersion = "25.05";
}
