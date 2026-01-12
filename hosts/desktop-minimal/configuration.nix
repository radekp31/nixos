# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib,... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_6_6;
  boot.kernelParams = [
    "systemd.default_timeout_stop_sec=10"
    "systemd.shutdown_timeout=5"
    "intel_iommu=on"
    "reboot=pci"
    "acpi=force"
  ];

  boot.blacklistedKernelModules = [
    "nouveau"
    "radeon"
    "amdgpu"
    "dm_mod"
  ];
  
  boot.kernel.sysctl = {
    "kernel.sysctl" = 1;
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
    DefaultTimeoutAbortSec=10s
    ShutdownWatchdogSec=off
    RuntimeWatchdogSec=off
  '';

  systemd.watchdog.runtimeTime = "off";
  systemd.watchdog.rebootTime = "off";
  systemd.watchdog.kexecTime = "off";

  systemd.services.systemd-udevd.serviceConfig = {
    TimeoutStopSec = 1;
    KillMode = "control-group";
    KillSignal = "SIGKILL";
    SendSIGKILL = "yes";
    FinalKillSignal = "SIGKILL";
   };

  systemd.services.systemd-udevd.unitConfig = {
    DefaultDependencies = "no";
  };
  
  systemd.services.systemd-udev-trigger.serviceConfig.TimeoutStopSec = 1;
  systemd.services.systemd-udev-settle.serviceConfig.TimeoutStopSec = 1;
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.systemd-udev-settle.enable = false;
  

  services.udev.extraRules = ''
    ACTION=="remove", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", RUN+="${pkgs.coreutils}/bin/true"
  '';

  services.lvm = {
    enable = false;
    boot.thin.enable = false;
  }; 

  environment.etc."lvm/lvm.conf".text = ''
    devices {
      use_lvmetad = 0
    }
  '';

  virtualisation.waydroid.enable = false;

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
      ovmf = {
        enable = true;
      };
    };
  };

  systemd.services.libvirtd.serviceConfig = {
    TimeoutStopSec = 5;
    KillMode = lib.mkForce "mixed";
  };

  systemd.services.virtlogd.serviceConfig.TimeoutStopSec = 5;
  systemd.services.virtlockd.serviceConfig.TimeoutStopSec = 5;
  systemd.services.libvirt-guests.serviceConfig.TimeoutStopSec = 10;

  virtualisation.spiceUSBRedirection.enable = true;

  services.xserver.desktopManager.kodi.enable = true;
  
  networking.hostName = "elitedesk-media"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "cs_CZ.UTF-8";
    LC_IDENTIFICATION = "cs_CZ.UTF-8";
    LC_MEASUREMENT = "cs_CZ.UTF-8";
    LC_MONETARY = "cs_CZ.UTF-8";
    LC_NAME = "cs_CZ.UTF-8";
    LC_NUMERIC = "cs_CZ.UTF-8";
    LC_PAPER = "cs_CZ.UTF-8";
    LC_TELEPHONE = "cs_CZ.UTF-8";
    LC_TIME = "cs_CZ.UTF-8";
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Enable the XFCE Desktop Environment.
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.desktopManager.xfce.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Intel graphics driver enable
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime
    ];
  };

 
  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
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
    description = "radekp";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "kvm" "video" "audio" "cdrom" "optical"];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  services.udisks2.enable = true;
  security.polkit.enable = true;
  services.gvfs.enable = true;
  programs.dconf.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  environment.etc."sway/config".text = ''
    set $mod Mod4

    bindsym $mod+Space exec ${pkgs.wofi}/bin/wofi --show drun

    bindsym $mod+Shift+c reload

    bindsym $mod+Return exec ${pkgs.foot}/bin/foot

    bindsym $mod+Shift+q kill

    bindsym $mod+Shift+e exec swaymsg exit

  '';
  
  programs.foot = {
   enable = true;
   settings = {
     main = {
       font = "DejaVu Sans Mono:size=14";
       dpi-aware = "yes";
     };
   };
  };
  # Autologin
  services.getty.autologinUser = "radekp";

  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec sway
    fi

    alias ll = "ls -lah"

    export EDITOR="vim"

   if command -v fzf-share >/dev/null; then
     source "$(fzf-share)/key-bindings.bash"
     source "$(fzf-share)/completion.bash"
   fi

  '';

  programs.bash = {
    shellAliases = {
      ll = "ls -lah";
    };

  }; 


  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true; 
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget 
    
    foot
    wofi
    fzf
 
    (python3.withPackages (ps: with ps; [
      inquirer
      requests
      tqdm
    ]))
    lzip
  
    htop
    curl
    wget
    git
 
    mpv
    firefox

    gcompris

    #Virtualisation
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol

    brasero
    cdrtools
    libburn
    xfce.xfburn
    # GStreamer plugins for audio decoding
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav # For almost everything else


  ];

  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = "/run/current-system/sw/lib/gstreamer-1.0";

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
   networking.firewall.allowedTCPPorts = [ 22 ];
   networking.firewall.allowedUDPPorts = [ 22 ];
   #Or disable the firewall altogether.
   networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
