# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

#TODO
#1/ fix hardcoded values
#2/ keep only relevant config in configuration.nix 
#   split into more .nix files or move it to home.nix  
#4/ fix ugly formatting (extraneous comments, indentation)
#5/ test removing some configs that might be included by default (openssh, ...)
#6/ Make the config functional for fresh machines via git pull
#7/ Make the config "interactive"
#	- automatic user creation from list - https://discourse.nixos.org/t/creating-users-from-a-list/34014/5
#	- multiple profiles available instead of just having modules/default.nix


{ config, pkgs, lib,  ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      <home-manager/nixos>
      ./hardware-configuration.nix
      ./nvidia-drivers.nix
      #(import ./modules)
      ./modules/default.nix
    ];

  # Enable experimental features
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Configure Nixpkgs to use the unstable channel for system-wide packages
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import <nixos-unstable> {config = pkgs.config; };
    };
  };

  # Configure rebuild VM access

  users.users.vmtest = {
    isSystemUser = true;
    initialPassword = "1234";
    group = "vmtest";
    shell = pkgs.bash;
  };

  users.groups.vmtest = {};

  virtualisation.vmVariant = {
    virtualisation = {
      memorySize =  2048; 
      cores = 2;         
    };
  };

   #setup SSH
   programs.ssh.startAgent = true;
   services.openssh.enable = true;

  # Use systemd timer to periodically push changes to GitHub
  systemd.services.uploadDotfiles = {
    enable = true;
    description = "Upload dotfiles to GitHub";
    serviceConfig = {
      ExecStart = "${pkgs.zsh}/bin/zsh /etc/nixos/modules/scripts/upload-dotfiles.sh";
      User = "radekp";
    };
    wantedBy = [ "multi-user.target" ];
  };

#  systemd.timers.uploadDotfilesTimer = {
  systemd.timers.uploadDotfiles = {
    description = "Timer to upload dotfiles to GitHub";
    timerConfig = {
      OnCalendar = "0/12:00:00"; # Runs every 12 hours, adjust as needed
      Persistent = true; # Ensure that job runs even after missed schedule
    };
    wantedBy = [ "timers.target" ];
  };

  # Bootloader.
  boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.extraEntries = ''
      set gfxpayload=keep
      set gfxmode=1920x1080
      set fastboot=1
    '';
    boot.loader.timeout = 1; #F
    boot.loader.grub.timeoutStyle = "hidden";
  # test plymouth
  
  # boot.plymouth = {
  #    enable = true;
  #    theme = "spinfinity";
     # themePackages = with pkgs; [
     #   # By default we would install all themes
     #   (adi1090x-plymouth-themes.override {
     #     selected_themes = [ "rings" ];
     #   })
     # ];
   # };

    # Enable "Silent Boot"
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = true;
    boot.kernelParams = [
     # "quiet"
     # "splash"
      "boot.shell_on_fail"
      #"loglevel=3"
      #"rd.systemd.show_status=false"
      #"rd.udev.log_level=3"
      #"udev.log_priority=3"
      #"nvidia-drm.modeset=1"  # NVIDIA-specific setting
      #"console=tty1"
    ];
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    #loader.timeout = 0;

  networking.hostName = "nixos-desktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable virtualization
  virtualisation.libvirtd.enable = true;
  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

  # Set your time zone.
  time.timeZone = "Europe/Prague"; #value before "Europe/Amsterdam"

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  
  # Enable Budgie desktop
  services.xserver.desktopManager.budgie.enable = true;

  # Enable bspwm
  services.xserver.windowManager.bspwm.enable = true;
  services.displayManager.defaultSession = "none+bspwm";
 
  # Enable ly
  services.displayManager.ly.enable = true;

  #Automount USB devices
  #services.devmon.enable = true;
  #services.gvfs.enable = true;
  #services.udisks2.enable = true; 

  #Enable picom
  services.picom.enable = true;
  services.picom.settings = {
    
      # Enable shadows
      shadow = true;
      shadow-radius = 12;
      shadow-opacity = 0.7;
      shadow-offset-x = -7;
      shadow-offset-y = -7;

      # Enable fading
      fading = true;
      fade-delta = 5;
      fade-in-step = 0.03;
      fade-out-step = 0.03;

      # Enable transparency for inactive windows
      inactive-opacity = 0.9;
      active-opacity = 1.0;
      frame-opacity = 0.8;
      inactive-opacity-override = false;

      # Blur background of transparent windows
      blur = {
        method = "kernel";
        strength = 5;
      };

      # Enable vsync to avoid screen tearing
      vsync = true;

      # Use rounded corners
      corner-radius = 0;

      # Disable shadows for specific applications
      shadow-exclude = [
        "class_g = 'Polybar'"
        "class_g = 'feh'"
        "class_g = 'Alacritty'"
      ];
    };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.radekp = {
    isNormalUser = true;
    description = "Radek Polasek";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "video" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  #Set up Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

 # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
 #   "steam"
 #   "steam-original"
 #   "steam-run"
 # ];
  
  #Set up ZSH
  users.defaultUserShell = pkgs.zsh;
  programs.zsh = {
  enable = true;
#  sessionVariables = {
#  };
  promptInit = ''
    source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
  '';
  enableCompletion = true;
  autosuggestions.enable = true;
  syntaxHighlighting.enable = true;
  shellInit = ''
    #Enable fzf plugin
    source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
  '';

  shellAliases = {
    ll = "ls -lah";
    update = "sudo nixos-rebuild switch";
    edit = "sudoedit /etc/nixos/configuration.nix";
    updatevm = "nixos-rebuild switch build-vm && dunstify \"NixOS Rebuild\" \"VM is ready\"";
  };

  ohMyZsh = {
    enable = true;
    plugins = [ "git" "sudo" "fzf" "eza"
    ];
    theme = "robbyrussell";
  };

  };

 

  # Install firefox.
  programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget

  #git # this thing basically doesnt function properly without git

  # TEST
  qmk
  qmk_hid
  qmk-udev-rules
  udiskie
  manix
  alacritty-theme

  # Packages

  neofetch #distro stats
  curl
  git
  openssh
  htop #system monitor
  eza #ls on steroids 
  fzf # fuzzy finder
  plymouth # boot customization
  feh # lighweight wallpaper management
  gwe # fan control for Nvidia GPUs
  qemu_kvm # virtualisation
  spice-vdagent # copy/paste agent for VMs
  virt-viewer # VM viewer
  tree # dir tree structure viewer
  polybarFull # status bar
  alacritty #GPU accelerated terminal emulator
  rofi # awesome launch menu
  rofi-power-menu #awesome power menu
  yazi #cli based file manager - its awesome, check nix options as well!
  picom #x11 lightweight compositor
  ly # TUI login screen
  ntfs3g
  betterlockscreen # cool lockscreen built on i3 lock
  shutter # snipping tool
  dunst
  lld_18

 
  # Zsh

  zsh #I use zsh btw
  oh-my-zsh # I use fancy zsh btw
  zsh-powerlevel10k # I use ultra fancy zsh btw
  zsh-fzf-tab
  zsh-fzf-history-search 
  zsh-autosuggestions 
  zsh-syntax-highlighting
  meslo-lgs-nf # font

  # Home manager
  home-manager 

  # Libre Office

  libreoffice-qt # libre office
  hunspell # grammar checking for libre office
  hunspellDicts.en_US-large # enUS dictionary for grammar checking
  hunspellDicts.en_GB-large # enGB dictionary for grammar checking
  hunspellDicts.cs_CZ # csCz dictionary for grammar checking
  ];
  
  # Install fonts from NerdFonts
  fonts.packages = with pkgs; [

    (nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];
  
  # Enable dconf
  programs.dconf.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
