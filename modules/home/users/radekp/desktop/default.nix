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
    ../../../apps/desktop/niri
    ../../../apps/desktop/noctalia
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

  #xdg.portal = {
  #  enable = true;
  #};

  programs.rofi = {
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
  #xdg = {
  #  enable = true;
  #};

  programs.waybar = {
    enable = false;
    systemd.enable = true;
  };

  #move to separate module
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = ''
             	local wezterm = require 'wezterm'
             	local act = wezterm.action
             	local config = {}

             	if wezterm.config_builder
             	then
             	  config = wezterm.config_builder()
             	  config:set_strict_mode(true)
             	end

             	-- General settings

             	config.max_fps = 144
             	config.animation_fps = 144
             	config.front_end = "WebGpu"
             	config.webgpu_power_preference = "HighPerformance"
             	config.audible_bell = "Disabled"

             	-- Appearance
             	config.color_scheme = 'Tokyo Night Moon'
             	config.window_decorations = "NONE"
             	config.use_fancy_tab_bar = false
             	config.window_frame = {
             	  font_size = 16.5
             	}
             	config.font = wezterm.font 'Dejavu Sans Mono'
      config.font_size = 16

        -- Lazy loading

        config.tab_bar_at_bottom = false
        config.scrollback_lines = 5000 -- Limit scrollback to reduce memory
        config.enable_scroll_bar = false -- Disable scroll bar for performance
        config.harfbuzz_features = {} -- Minimal font features initially

             	-- Keymaps
             	config.keys = {

             	  -- Pane splitting
             	  {
             	    key = 'mapped:+',
             	    mods = 'SHIFT|ALT',
             	    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
             	  },
             	  {
             	    key = 'mapped:_',
             	    mods = 'SHIFT|ALT',
             	    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
             	  },
             	  -- Pane focus movement
             	  {
             	    key = 'LeftArrow',
             	    mods = 'ALT',
             	    action = act.ActivatePaneDirection 'Left'
             	  },
             	  {
             	    key = 'RightArrow',
             	    mods = 'ALT',
             	    action = act.ActivatePaneDirection 'Right'
             	  },
             	  {
             	    key = 'UpArrow',
             	    mods = 'ALT',
             	    action = act.ActivatePaneDirection 'Up'
             	  },
             	  {
             	    key = 'DownArrow',
             	    mods = 'ALT',
             	    action = act.ActivatePaneDirection 'Down'
             	  },

             	  -- Pane movement
             	  {
             	    key = 'LeftArrow',
             	    mods = 'SHIFT|ALT',
             	    action = act.RotatePanes 'CounterClockwise',
             	  },
             	  { key = 'RightArrow',
             	    mods = 'SHIFT|ALT',
             	    action = act.RotatePanes 'Clockwise'
             	  },

             	  -- Lanch launch_menu
             	  {
             	    key = 'l',
             	    mods = 'ALT',
             	    action = wezterm.action.ShowLauncher
             	  },
             	}

             	-- Right click Copy

             	config.mouse_bindings = {
             	  {
             	   event = { Down = { streak = 1, button = "Right" } },
             	   mods = "NONE",
             	   action = wezterm.action_callback(function(window, pane)
             	     local has_selection = window:get_selection_text_for_pane(pane) ~= ""
             	     if has_selection then
             	       window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
             	       window:perform_action(act.ClearSelection, pane)
             	     else
             	       window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
             	     end
             	   end),
             	  },
             	 }

             	-- Adding lanch menu items
             	config.launch_menu = {
             	  {
             	    -- Optional label to show in the launcher. If omitted, a label
             	    -- is derived from the `args`
             	    -- label = 'PowerShell',
             	    -- The argument array to spawn.  If omitted the default program
             	    -- will be used as described in the documentation above

             	    -- args = { 'pwsh.exe' },

             	    -- You can specify an alternative current working directory;
             	    -- if you don't specify one then a default based on the OSC 7
             	    -- escape sequence will be used (see the Shell Integration
             	    -- docs), falling back to the home directory.

             	    -- cwd = { 'C:\\' },

             	    -- You can override environment variables just for this command
             	    -- by setting this here.  It has the same semantics as the main
             	    -- set_environment_variables configuration option described above
             	    -- set_environment_variables = { FOO = "bar" },
             	  }
             	}
             	return config


    '';
  };

  programs.bat = {
    enable = true;
    config = {
      paging = "never";
      theme = "tokyo-night-storm";
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
    wezterm # Terminal emulator
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
