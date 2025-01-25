#/nix/store/kkin0nrpavpdpkinh2w9rrb8fxyr9l6b-init.vim Edit this configuration file to define what should be installed on
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

{ config
, pkgs
, lib
, ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    #<home-manager/nixos>
    "${
      builtins.fetchTarball {
        url = "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
	sha256 = "wJQCxyMRc4P26zDrHmZiRD5bbfcJpqPG3e2djdGG3pk=";
      }
    }/nixos"

    ./hardware-configuration.nix
    ./nvidia-drivers.nix
    ./modules/default.nix
    ./modules/apps/nixvim/nixvim.nix
    #./modules/apps/qmk/qmk.nix
    #./modules/apps/qemu/qemu.nix

  ];

  # Configure Nixpkgs to use the unstable channel for system-wide packages
  nixpkgs.config = {
    allowUnfree = true;
    channels = {
      enable = true;

      urls = [ "https://nixos.org/channels/nixpkgs-unstable" ];
    };
    packageOverrides = pkgs: {
      unstable = import <nixos-unstable> { config = pkgs.config; };
    };
    overlays = [
      (import (
        builtins.fetchTarball {
          url = "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
          sha2656 = "wJQCxyMRc4P26zDrHmZiRD5bbfcJpqPG3e2djdGG3pk=";
        }
      ))
    ];
  };

  #System auto upgrades
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
  };

  # Nix settings
  # - automatic garbage collection
  # - automatic store optimisation
  # - enabling flakes
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
  };

  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 2048; # Set memory size
      diskSize = 10;
      cores = 2;
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true; # Require password for sudo
    extraConfig = ''
      user ALL=(ALL) NOPASSWD: /usr/bin/nvidia-settings *
    '';
    extraRules = [
      {
        commands = [
          {
            command = "/run/current-system/sw/bin/nvidia-settings";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nvidia-smi";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/journalctl";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/dmesg";
            options = [ "NOPASSWD" ];
          }
        ];
        groups = [ "wheel" ];
      }
    ];
  };

  #setup SSH

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.initrd.availableKernelModules = [
    "nvidia"
    "nvme"
    "vesafb"
    "xhci_pci"
    "usbhid"
  ];
  boot.initrd = {
    enable = true;
  };
  boot.supportedFilesystems = [ "ntfs" ];

  #boot.loader.systemd-boot.enable = false;
  #boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.grub.enable = true;
  #boot.loader.grub.device = "/dev/sda";
  #boot.loader.grub.useOSProber = true;
  #boot.loader.grub.extraEntries = ''
  #  set gfxpayload=keep
  #  set gfxmode=auto
  #'';
  #boot.loader.timeout = 1; #F
  #boot.consoleLogLevel = 0;
  #boot.loader.grub.timeoutStyle = "menu";

  # Enable "Silent Boot"
  #boot.consoleLogLevel = 0;

  #Fix OOM freezes
  #boot.kernelPackages = pkgs.linuxPackages_6_6; # works with beta nvidia driver
  boot.kernelPackages = pkgs.linuxPackages_zen;

  #zramSwap = {
  #  enable = true;
  #  algorithm = "lz4"; #lz4 works
  #};

  boot.extraModprobeConfig = ''
    options nvidia-drm modeset=1
  '';

  powerManagement.cpuFreqGovernor = "performance";

  boot.kernelParams = [
    #"quiet"
    #"splash"
    "boot.shell_on_fail"
    #"fsck.mode=skip"
    "tsc=unstable"
    "trace_clock=local"

    #Disable USB power management
    "usbcore.autosuspend=-1"
    "usbcore.debug=1"
    "video=1920x1080"
  ];

  networking.hostName = "nixos-desktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Environment variables
  environment.variables = {
    DISPLAY = ":0";
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERM = lib.mkDefault "xterm-256color";
    LD_LIBRARY_PATH = "${pkgs.libglvnd}/lib";
    XAUTHORITY = "/run/user/0/.Xauthority";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_DIRS = "/etc/xdg";
    XDG_CONFIG_HOME = "$HOME/.config";
    #XDG_DATA_DIRS = "/usr/local/share/:/usr/share/";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };
  # Enable virtualization
  #virtualisation.libvirtd.enable = true;
  boot.kernelModules = [
    "kvm-amd"
    "kvm-intel"
  ];

  # Set your time zone.
  time.timeZone = "Europe/Prague"; # value before "Europe/Amsterdam"

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

  #Add udev rules for GMMK2
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="320f", ATTR{idProduct}=="504b", MODE="0666"  	
  '';

  #Enable Android Debug Bridge
  programs.adb.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # Enable Budgie desktop
  #services.xserver.desktopManager.budgie.enable = true;
  #services.xserver.displayManager.lightdm.enable = true;

  # Enable bspwm
  services.xserver.windowManager.bspwm.enable = true;
  services.displayManager.defaultSession = "hyprland-uwsm";

  # Enable ly
  services.displayManager.ly.enable = true;

  # Wayland + Hyprland attempt
  #programs.uwsm.enable = true;
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;
  # Attempt to fix Hyprland high VRAM usage
  environment.etc = {
    "nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.txt" = {
      text = ''
        {
            "rules": [
        	{
        	    "pattern": {
        		"feature": "procname",
        		"matches": "Hyprland"
        	    },
        	    "profile": "Limit Free Buffer Pool On Wayland Compositors"
        	}
            ],
            "profiles": [
        	{
        	    "name": "Limit Free Buffer Pool On Wayland Compositors",
        	    "settings": [
        		{
        		    "key": "GLVidHeapReuseRatio",
        		    "value": 1
        		}
        	    ]
        	}
            ]
        }
      '';

      # The UNIX file mode bits
      mode = "0777";
    };
  };

  #services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
  services.xserver.enable = true;
  #services.xserver.deviceSection = ''
  #        Identifier "NVIDIA GPU"
  #        Driver "nvidia"
  #        Option "PrimaryGPU" "Yes"
  #        Option "ConnectedMonitor" "DFP-2,DFP-3"
  #	  Option "MetaModes" "2560x1440 +0+0, 1680x1050 -2560+0"
  #'';
  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --time-format '%I:%M %p | %a -- %h | %F' --cmd Hyprland";
  };
  #services.displayManager.sddm.enable = true;
  #services.displayManager.sddm.wayland.enable = true;
  #services.displayManager.sddm.enableHidpi = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true; # hardware.opengl.enable on older versions
  hardware.nvidia.modesetting.enable = true;

  xdg.portal = {
    enable = true;
  };

  # End of Hyprland attempt

  #Enable picom
  services.picom.enable = false;
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
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

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
    description = "Radek Polasek";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];
    #home.file = pkgs.lib.mkForce /home/radekp/.config/nixpkgs/home.nix; # nonsense - but it will have to be crated on autonated user creation
    packages = with pkgs; [
      #  thunderbird
    ];
  };

  home-manager.users.radekp = import /etc/nixos/home-manager/home.nix;

  #Set up Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-run"
  ];

  #Set up ZSH
  users.defaultUserShell = pkgs.zsh;
  programs.zsh = {
    enable = true;
    promptInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellInit = ''
      # Enable fzf plugin
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    
      # Command to run after user login
      
      # unmount remote, just in case its broken
      # redirection of stderr to some log file could be more useful
      #fusermount -uz /media/WDRED/OneDrive > /dev/null 2>&1

      # mount the remote
      # redirection of stderr to some log file could be more useful
      #nohup rclone cmount --vfs-cache-mode writes onedrive: /media/WDRED/OneDrive > /dev/null 2>&1 < /dev/null &! disown > /dev/null 2>&1

      #if [ $(ls -A /media/WDRED/OneDrive | wc -l) -eq 0 ]; then
      #nohup rclone cmount --vfs-cache-mode writes onedrive: /media/WDRED/OneDrive > /dev/null 2>&1 < /dev/null &! disown > /dev/null 2>&1
      #fi

    '';

    shellAliases = {
      update = "sudo nixos-rebuild switch";
      edit = "sudoedit /etc/nixos/configuration.nix";
      update-vm = "sudo nixos-rebuild switch build-vm && dunstify \"NixOS Rebuild\" \"VM is ready.\"";
      rebuild = "sudo nixos-rebuild test && dunstify \"NixOS Rebuild\" \"Test rebuild is done.\"";
      rebuild-switch = "sudo nixos-rebuild switch && dunstify \"NixOS Rebuild\"\"Switch rebuild is done.\"";
      manix = ''
        manix "" | grep '^# ' | sed 's/^# \\(.*\\) (.*/\\1/;s/ (.*//;s/^# //' | fzf --preview="manix '{}'" | xargs manix
      '';

      ll = "eza -lahg --all";
      llt = "eza -lahg --tree --git-ignore";
      lld = "eza -lahgd";
      man = "tldr";
      cat = "bat -pp";
      #icat = "kitty icat";
      icat = "wezterm imgcat";

      nix-push-config = "nix fmt && git fetch --all && git add . && git commit -m \"update on $(date '+%Y-%m-%d %H:%M:%S')\" && git push";

    };

    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "fzf"
        "eza"
      ];
      theme = "robbyrussell";
    };

  };

  # Install firefox.
  programs.firefox.enable = true;

  # Setup neovim
  programs.neovim = {
    enable = false;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    package = pkgs.neovim-unwrapped;
    # Neovim configure section for custom RC and plugins
    configure = {
      customRC = ''
                " Enable Tokyo Night color scheme
        	colorscheme tokyonight-night

        	" Enable row numbers
                set number
                set relativenumber

                " Clear screen after exit
        	lua vim.api.nvim_create_autocmd("VimLeavePre", { command = "silent !clear" })
              
        	'';

      #colorscheme tokyonight-night
      packages.myVimPackage = with pkgs.vimPlugins; {

        # loaded on launch
        start = [
          #tokyonight-nvim
          #vim-lsp
          #vim-lsp-settings
          #nvim-treesitter
          #cmp-nvim-lsp
          #nvim-cmp
        ];
        # manually loadable by calling `:packadd $plugin-name`
        opt = [
          #tokyonight-nvim
        ];
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

    # TEST
    qmk
    qmk_hid
    qmk-udev-rules
    udiskie
    unzip
    p7zip
    pciutils
    smartmontools
    thinkfan
    lm_sensors
    unetbootin
    nixos-icons
    dejavu_fonts

    # Wayland + Hyprland
    xorg.xhost
    # Packages

    neofetch # distro stats
    manix # nix options manual
    curl
    git # NixOS sucks without git
    openssh
    htop # system monitor
    eza # ls on steroids
    fzf # fuzzy finder
    plymouth # boot customization
    feh # lighweight wallpaper management
    gwe # fan control for Nvidia GPUs
    qemu_kvm # virtualisation
    spice-vdagent # copy/paste agent for VMs
    virt-viewer # VM viewer
    tree # dir tree structure viewer
    polybarFull # status bar
    alacritty # GPU accelerated terminal emulator
    alacritty-theme
    rofi # awesome launch menu
    rofi-power-menu # awesome power menu
    picom # x11 lightweight compositor
    ly # TUI login screen
    ntfs3g
    betterlockscreen # cool lockscreen built on i3 lock
    shutter # snipping tool
    dunst # notification tool
    lld_18
    opera
    jq
    yt-dlp
    ffmpeg
    nmon
    bat
    tldr
    btop
    nurl # get tarball hashes

    # Zsh

    zsh # I use zsh btw
    oh-my-zsh # I use fancy zsh btw
    zsh-powerlevel10k # I use ultra fancy zsh btw
    zsh-fzf-tab
    zsh-fzf-history-search
    zsh-autosuggestions
    zsh-syntax-highlighting
    meslo-lgs-nf # font

    # NVIM
    vimPlugins.tokyonight-nvim
    xclip
    wl-clipboard
    nil

    # Home manager
    home-manager

    # Libre Office

    libreoffice-qt # libre office
    hunspell # grammar checking for libre office
    hunspellDicts.en_US-large # enUS dictionary for grammar checking
    hunspellDicts.en_GB-large # enGB dictionary for grammar checking
    hunspellDicts.cs_CZ # csCz dictionary for grammar checking

    # Fonts
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.inconsolata
    nerd-fonts.meslo-lg
    nerd-fonts.space-mono
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-sans
    nerd-fonts.agave
    nerd-fonts.hack
    nerd-fonts.symbols-only
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
  system.stateVersion = "unstable"; # Did you read the comment?

}
