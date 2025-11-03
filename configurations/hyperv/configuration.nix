# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    <nixpkgs/nixos/modules/virtualisation/hyperv-guest.nix>
  ];

  virtualisation.hypervGuest.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_6_6;

  boot.blacklistedKernelModules = ["hyperv_fb" "modesetting" "uio" "uio_hv_generic"];
  boot.kernelModules = ["hv_balloon" "hv_netvsc" "hv_storvsc" "hv_vmbus" "hv_utils" "hv_uio_fcopy"];

  boot.plymouth.enable = true;

  # Use the GRUB 2 boot loader.
  boot.loader = {
    #efi = {
    #  canTouchEfiVariables = true;
    #  efiSysMountPoint = "/boot/efi";
    #};
    grub = {
      #efiSupport = true;
      device = "/dev/sda";
    };
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-tools
      libva-vdpau-driver
      libvdpau-va-gl
      libva1
      nvidia-vaapi-driver
    ];
  };

  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.desktopManager = {
    xterm.enable = true;
    xfce.enable = true;
  };
  services.displayManager.defaultSession = "xfce";
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.videoDrivers = [ "fbdev" ];
  services.xserver.libinput.enable = true;
  
  nixpkgs.config.allowUnfree = true;

  console.keyMap = "us";

  #Making Xterm not being eye cancer
  #This doesnt work though
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

  programs.git = {
    enable = true;
  };

  programs.bash = {
    completion.enable = true;
    enableLsColors = true;
    shellInit = ''
      bind "set show-all-if-ambiguous on"
      bind "TAB:menu-complete"
      source ${pkgs.git}/share/git/contrib/completion/git-prompt.sh
    '';
    interactiveShellInit = ''
      if [ "$TERM" = "xterm" ] || [ "$TERM" = "xterm-256color"]; then
        xrdb -merge /etc/X11/Xresources
      fi
    '';
  };

  services.xrdp = {
    enable = true;
    defaultWindowManager = "xfce4-session";
    openFirewall = true;
  };

  services.dbus.enable = true;

  services.gnome.core-utilities.enable = true;

  #networking.hostName = "nixos"; # Define your hostname. Important for k8s where every node required its own unique hostname
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  networking.enableIPv6 = false;
  boot.kernel.sysctl."net.ipv6.conf.eth0.disable_ipv6" = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

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

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.radekp = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  programs.firefox.enable = true;

  #Making bash nicer place to live in
  # TODO - maybe try bash-it easy theme

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
    xsel
    xrdp
    dbus
    linuxKernel.packages.linux_6_6.hyperv-daemons
    fzf
    jq
    htop
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  programs.ssh.askPassword = lib.mkForce "${pkgs.x11_ssh_askpass}/libexec/x11_ssh_askpass";
  # Open ports in the firewall.
   networking.firewall.allowedTCPPorts = [ 3389 ];
  # networking.firewall.allowedUDPPorts = [ 10257 10259 6443 443 8888 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  #networking.extraHosts = ''
  #  172.28.200.82 api.kube
  #'';

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
