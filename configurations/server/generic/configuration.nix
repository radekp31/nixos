# flakes need to be enabled
# nixpkgs nees to be added to channels
# shell need to be forced by mkForce to bash
# $NIX_PATH is broken - use this for rebuild:
#
# <export NIX_PATH=nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:nixos-config=/etc/nixos/configuration.nix
#nixos-rebuild switch
#
#
# port 22 needs to be opened



{ config, lib, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  networking.hostName = "nixos-vps1"; # Define your hostname.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set nix flakes, and $NIX_PATH (hopefully this also fixed nix channels - update: It doesnt)
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
      "/nix/var/nix/profiles/system/channels"
    ];
  };

  #Fix nix-channel?
  nixpkgs.flake.source = lib.mkForce "github:nixos/nixpkgs/nixos-24.05";

  #services.openssh.enable = true;
  services.openssh = {
    enable = true;
    # Optional: Configure SSH settings
    settings = {
      PasswordAuthentication = false; # Set to false to disable password login
    };
  };

  networking.firewall = {
    enable = true; # Enable the firewall
    allowedTCPPorts = [ 22 ]; # Allow SSH connections ; 80 is testing of remote deployment from localhost
    allowedUDPPorts = [ 53 123 ]; # Allow DNS and NTP
    # Optional: if you're using IPv6
    # allowedTCPPorts = [ 22 ];       # Same for IPv6
    extraCommands = ''
    '';
  };

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.root = {
    isSystemUser = true;
    shell = lib.mkForce pkgs.bash;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      git
      curl
      vim
    ];
    openssh = {
      authorizedKeys = {
        keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzoVRVWpxFy1dOe0vVrtv2c/i9GixoyUDKpgsuruSG2 radekp@nixos-desktop"
        ];
      };
    };
  };

  programs.bash = {
    shellInit = ''
      bind "set show-all-if-ambiguous on"
      bind "TAB:menu-complete"
    '';
  };

  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };


  system.stateVersion = "25.05";

}
