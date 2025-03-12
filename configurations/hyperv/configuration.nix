# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <nixpkgs/nixos/modules/virtualisation/hyperv-guest.nix>
    ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.blacklistedKernelModules = [ "hyperv_fb" "modesetting" ];
  boot.kernelModules = [ "hv_balloon" "hv_netvsc" "hv_storvsc" "hv_vmbus" "hv_utils" "hv_uio_fcopy" ];

  boot.plymouth.enable = true;

  boot.loader = {
    grub = {
      device = "/dev/sda";
    };
  };

  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "radekp";
      lightdm.enable = true;
    };
    desktopManager.budgie.enable = true;
    videoDrivers = [ "fbdev" "vesa" ];
  };

  nixpkgs.config.allowUnfree = true;

  console.keyMap = "us";

  #Making Xterm not being eye cancer

  environment.etc."X11/Xresources".text = ''
    xterm*background: black
    xterm*foreground: white
    xterm*faceName: VeraMono
    xterm*faceSize: 13
    xterm*saveLines: 4096
    xterm*scrollBar: true
    xterm*rightScrollBar: true
    xterm*renderFont: true
  '';


  programs.bash.interactiveShellInit = ''
    if [ "$TERM" = "xterm" ] || [ "$TERM" = "xterm-256color"]; then
      xrdb -merge /etc/X11/Xresources
    fi 
  '';

  services.xrdp = {
    enable = true;
    defaultWindowManager = "budgie-desktop";
  };

  services.dbus.enable = true;

  services.gnome.core-utilities.enable = true;

  virtualisation.hypervGuest.enable = true;

  networking.hostName = "nixos-hyperv";
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.radekp = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree

    ];
  };

  #Supply corporations with your private data
  programs.firefox.enable = true;

  #Making bash nicer place to live in
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    git
    xclip
    xsel
    freerdp
    autocutsel
    dbus
    linuxKernel.packages.linux_6_13.hyperv-daemons
    fzf
    shellharden
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  #system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}
