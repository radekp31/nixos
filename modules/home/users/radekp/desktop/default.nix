{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Setup zsh
    ../../../shells/zsh

    # Desktop (Niri + Noctalia)
    inputs.niri.homeModules.niri
    #../../../apps/desktop/niri
    #../../../apps/desktop/noctalia

    # Terminal emulator
    ../../../apps/foot

    # Zen browser
    ../../../apps/zen_browser

    # Enable catppuccin
    inputs.catppuccin.homeModules.catppuccin
  ];

  #Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Home Manager settings
  home.username = "radekp";
  home.homeDirectory = "/home/radekp";
  home.stateVersion = "25.05";
  home.sessionPath = [
    "/home/radekp/.nix-profile/bin/" # Required by Neovim and plugins (?)
  ];
  home.sessionVariables = {
    SDL_VIDEODRIVER = "wayland";
  };

  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "github.com" = {
        user = "git";
        hostname = "github.com";
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  services.ssh-agent = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  #Setup and configure git
  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "polasek.31@seznam.cz";
        name = "Radek Polasek";
      };

      init.defaultBranch = "main";
      safe.directory = "/etc/nixos";
      push.autoSetupRemote = "true";
    };
  };

  #Bash is needed for XDG vars - needs testing
  programs.bash = {
    enable = true;
  };

  programs.waybar = {
    enable = false;
    systemd.enable = true;
  };

  programs.bat = {
    enable = true;
    config = {
      paging = "never";
      #theme = "tokyo-night-storm";
      decorations = "never";
    };
    themes = {
      dracula = {
        src = pkgs.fetchFromGitHub {
          owner = "dracula";
          repo = "sublime"; # Bat uses sublime syntax for its themes
          rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
          sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
        };
        file = "Dracula.tmTheme";
      };
      tokyo-night-day = {
        src = "${pkgs.vimPlugins.tokyonight-nvim}/extras/sublime/tokyonight_day.tmTheme";
      };
      tokyo-night-moon = {
        src = "${pkgs.vimPlugins.tokyonight-nvim}/extras/sublime/tokyonight_moon.tmTheme";
      };
      tokyo-night-night = {
        src = "${pkgs.vimPlugins.tokyonight-nvim}/extras/sublime/tokyonight_night.tmTheme";
      };
      tokyo-night-storm = {
        src = "${pkgs.vimPlugins.tokyonight-nvim}/extras/sublime/tokyonight_storm.tmTheme";
      };
    };
    extraPackages = with pkgs.bat-extras; [batdiff batman batgrep batwatch];
  };

  programs.librewolf = {
    enable = true;
    settings = {
      "privacy.resistFingerprinting" = false;
      "privacy.resistFingerprinting.letterboxing" = true;
      "privacy.fingerprintingProtection" = true;
      "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";
      "privacy.trackingprotection.enabled" = true;
      "privacy.trackingprotection.excludelist" = "https://anthropic.com,https://api.anthropic.com,https://claude.ai";
      "webgl.disabled" = true;

      # Anonymize
      "general.settings.useragent.override" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0";

      #Zoom 110%
      #"layout.css.devPixelsPerPx" = "1.1";
    };
  };

  ##LibreWolf extensions
  ## setup tokyonight extension
  ## setup ublock origin
  ## setup canvasblocker
  ## setup privacy badger

  # OLD?
  home.file = {
    ".librewolf/profile/extensions/ublock@raymondhill.net.xpi".source = builtins.fetchurl {
      url = "https://addons.mozilla.org/firefox/downloads/file/4121906/ublock_origin-1.67.0.xpi";
      sha256 = "1cx5nzyjznhlyahlrb3pywanp7nk8qqkfvlr2wzqqlhbww1q0q8h";
    };
  };

  ##Bitwarden, link is changing, needs update
  home.file = {
    ".librewolf/profile/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi".source = builtins.fetchurl {
      url = "https://addons.mozilla.org/firefox/downloads/file/4440363/bitwarden_password_manager-2025.2.0.xpi";
      sha256 = "0x53sdqmz1nw1vwcs90g34aza69wrrzsrvah5x4215i6l9az7my4";
    };
  };

  #home.file = {
  #  ".librewolf/profile/extensions/ublock@raymondhill.net.xpi".source = ublock;
  #  ".librewolf/profile/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi".source = bitwarden;
  #  ".librewolf/profile/extensions/CanvasBlocker@kkapsner.de.xpi".source = canvasblocker;
  #  ".librewolf/profile/extensions/jid1-MnnxcxisBPnSXQ@jetpack.xpi".source = privacybadger;
  #};

  #TODO - Explore this
  #programs.lesspipe.enable = true;

  programs.firefox.enable = true;

  # Home packages
  home.packages = with pkgs; [
    # Niri
    xwayland-satellite

    # Security & Secrets
    age
    sops
    bitwarden-desktop
    bitwarden-cli

    # Development Tools
    cmake
    lld_18
    jq
    nurl
    ripgrep-all
    delta # Fancy git diff
    git
    nixd # Nix LSP server
    vimPlugins.nvim-lspconfig
    nix-prefetch-git
    nix-prefetch-git
    nix-prefetch
    nix-prefetch-docker
    nix-prefetch-scripts
    nixos-anywhere
    age
    sops
    nix-prefetch
    nix-prefetch-docker
    nix-prefetch-scripts
    nixos-anywhere
    age
    sops
    # System Utilities
    unzip
    wlr-randr
    termshark
    arp-scan-rs
    fastfetch
    fzf
    tldr
    btop
    dig
    tree
    usbutils
    ntfs3g # NTFS filesystem support
    # Media & Downloads
    yt-dlp
    ffmpeg
    vlc
    mpv
    qbittorrent-enhanced-nox
    # File Management & Cloud
    rclone
    qpdf
    nautilus
    # Virtualization
    qemu_kvm
    spice-vdagent
    virt-viewer
    # GUI Applications
    webcord # Discord alternative (better than discord)
    freecad-wayland
    # Hardware Control
    mangohud # GPU overlay
    # Clipboard
    wl-clipboard
    # Theming & Icons
    adwaita-icon-theme
    bibata-cursors
    qadwaitadecorations-qt6
    font-awesome_6
    # Fonts
    dejavu_fontsEnv
    meslo-lgs-nf
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.inconsolata
    nerd-fonts.meslo-lg
    nerd-fonts.space-mono
    nerd-fonts.ubuntu
    nerd-fonts.ubuntu-sans
    nerd-fonts.agave
    nerd-fonts.hack
    nerd-fonts.symbols-only

    # Office suite
    libreoffice-qt # libre office
    hunspell # grammar checking for libre office
    hunspellDicts.en_US-large # enUS dictionary for grammar checking
    hunspellDicts.en_GB-large # enGB dictionary for grammar checking
    hunspellDicts.cs_CZ # csCz dictionary for grammar checking
    # Zsh Plugins
    oh-my-zsh
    zsh-fzf-tab
    zsh-fzf-history-search
    zsh-autosuggestions
    zsh-syntax-highlighting
  ];
}
