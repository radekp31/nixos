{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  tokyonight-rofi-theme = import ../rofi-themes/rofi-themes.nix {inherit pkgs;};

  # Browser Extensions
  ublock = builtins.fetchurl {
    url = "https://addons.mozilla.org/firefox/downloads/file/4121906/ublock_origin-1.55.0.xpi";
    sha256 = "1cx5nzyjznhlyahlrb3pywanp7nk8qqkfvlr2wzqqlhbww1q0q8h";
  };

  bitwarden = builtins.fetchurl {
    url = "https://addons.mozilla.org/firefox/downloads/file/4440363/bitwarden_password_manager-2025.2.0.xpi";
    sha256 = "0x53sdqmz1nw1vwcs90g34aza69wrrzsrvah5x4215i6l9az7my4";
  };

  canvasblocker = builtins.fetchurl {
    url = "https://addons.mozilla.org/firefox/downloads/file/4097894/canvasblocker-1.6.1.xpi";
    sha256 = "1wc7hic6arq9xcylrcfh8pmxdjqpxq6f4ykm6w9q1h65rj81xv6l";
  };

  privacybadger = builtins.fetchurl {
    url = "https://addons.mozilla.org/firefox/downloads/file/4119137/privacy_badger-2024.2.6.xpi";
    sha256 = "1fq98naq5ajdm25s5np82z1w4zbxmm3ps8m5bw7w2a2b8hl9b44d";
  };
in {
  imports = [
  ];

  #Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Home Manager settings
  home.username = "radekp";
  home.homeDirectory = "/home/radekp";
  home.stateVersion = "25.05";
  home.enableNixpkgsReleaseCheck = false;
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 22;
  };
  home.sessionPath = [
    "/home/radekp/.nix-profile/bin/" # Required by Neovim and plugins (?)
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  #Niri attempt
  xdg.configFile."niri/config.kdl".source = ../niri/config.kdl;
  xdg.configFile."niri/pickwindow.sh".source = ../niri/pickwindow.sh;

  programs.fuzzel.enable = true; # Super+D in the default setting (app launcher)
  programs.swaylock.enable = true; # Super+Alt+L in the default setting (screen locker)
  #programs.waybar.enable = true; # launch on startup in the default setting (bar)
  services.mako.enable = true; # notification daemon
  services.swayidle.enable = true; # idle management daemon
  services.polkit-gnome.enable = true; # polkit
  #home.packages = with pkgs; [
  #  swaybg # wallpaper
  #];
  wayland.windowManager.sway = {
    enable = true;
    extraConfig = ''
      input * {
        xkb_layout "us"
        xkb_variant ""
      }
    '';
  };
  programs.alacritty = {
    enable = true; # Super+T in Niri with the default setting (terminal)
    settings = {
      font.normal = {
        #family = "Hack Nerd Font";
        family = "DejaVu Sans Mono";
      };
      font.size = 14;
    };
    theme = "catppuccin_macchiato";
  };

  #--- end of Niri attempt

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  #Setup and configure git
  programs.git = {
    enable = true;
    userName = "Radek Polasek";
    userEmail = "polasek.31@seznam.cz";
    extraConfig = {
      init.defaultBranch = "main";
      safe.directory = "/etc/nixos";
      push.autoSetupRemote = "true";
    };
  };

  #Bash is needed for XDG vars - needs testing
  programs.bash = {
    enable = true;
  };
  xdg = {
    enable = true;
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  #Waybar config
  home.file."${config.xdg.configHome}/waybar/config.jsonc" = {
    source = ../waybar/config.jsonc;
  };

  home.file."${config.xdg.configHome}/waybar/modules.json" = {
    source = ../waybar/modules.json;
  };

  home.file."${config.xdg.configHome}/waybar/style.css" = {
    source = ../waybar/style.css;
  };

  #Create power_menu.xml for waybar
  home.file.".config/waybar/power_menu.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <interface>
      <object class="GtkMenu" id="menu">
        <child>
      <object class="GtkMenuItem" id="suspend">
    	  <property name="label">Suspend</property>
            </object>
     </child>
     <child>
            <object class="GtkMenuItem" id="hibernate">
    	  <property name="label">Hibernate</property>
            </object>
     </child>
        <child>
            <object class="GtkMenuItem" id="shutdown">
    	  <property name="label">Shutdown</property>
            </object>
        </child>
        <child>
          <object class="GtkSeparatorMenuItem" id="delimiter1"/>
        </child>
        <child>
      <object class="GtkMenuItem" id="reboot">
    	  <property name="label">Reboot</property>
    		  </object>
        </child>
      </object>
    </interface>
  '';

  # Configure Rofi app launcher original
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    cycle = true;
    #font = "JetBrains Mono";
    font = "DejaVu Sans Mono";
    location = "top";
    plugins = [
      pkgs.rofi-calc
      pkgs.rofi-games
      pkgs.rofi-wayland
      pkgs.rofi-power-menu
    ];
    extraConfig = {
      modi = "drun,window";
      show-icons = true;
      width = 50; # Increase width (percentage of screen)
      height = 60; # Increase height (percentage of screen)
      drun-display-format = "{name}";
    };
    terminal = "${pkgs.wezterm}/bin/wezterm";
    #theme = "tokyo-night.rasi";
    theme = "${tokyonight-rofi-theme}/share/rofi/themes/tokyonight_big2.rasi";
  };

  #Rofi TokyoNight theme original
  home.file.".config/rofi/tokyo-night.rasi".text = ''
        /*
     * Tokyonight colorscheme for rofi
     * User: w8ste
     */


    // define colors etc.
    * {
        bg: #1A1B26;
        hv: #9274ca; // selector highlight
        primary: #C0CAF5;
        ug: #0B2447;
        font: "Inconsolata 11";
        background-color: @bg;
        //dark: @bg;
        border: 0px;
        kl: #C0CAF5; //font color
        black: #000000;

        transparent: rgba(46,52,64,0);
    }

    // defines different aspects of the window
    window {
        width: 700;
        /*since line wont work with height, i comment it out
        if you rather control the size via height
        just comment it out */
        //height: 500;

        orientation: horizontal;
        location: center;
        anchor: center;
        transparency: "screenshot";
        border-color: @transparent;
        border: 0px;
        border-radius: 6px;
        spacing: 0;
        children: [ mainbox ];
    }

    mainbox {
        spacing: 0;
        children: [ inputbar, message, listview ];
    }

    inputbar {
        color: @kl;
        padding: 11px;
        border: 3px 3px 2px 3px;
        border-color: @primary;
        border-radius: 6px 6px 0px 0px;
    }

    message {
        padding: 0;
        border-color: @primary;
        border: 0px 1px 1px 1px;
    }

    entry, prompt, case-indicator {
        text-font: inherit;
        text-color: inherit;
    }

    entry {
        cursor: pointer;
    }

    prompt {
        margin: 0px 5px 0px 0px;
    }

    listview {
        layout: vertical;
        //spacing: 5px;
        padding: 8px;
        lines: 12;
        columns: 1;
        border: 0px 3px 3px 3px;
        border-radius: 0px 0px 6px 6px;
        border-color: @primary;
        dynamic: false;
    }

    element {
        padding: 2px;
        vertical-align: 1;
        color: @kl;
        font: inherit;
    }

    element-text {
        background-color: inherit;
        text-color: inherit;
    }

    element selected.normal {
        color: @black;
        background-color: @hv;
    }

    element normal active {
        background-color: @hv;
        color: @black;
    }

    element-text, element-icon {
        background-color: inherit;
        text-color: inherit;
    }

    element normal urgent {
        background-color: @primary;
    }

    element selected active {
        background: @hv;
        foreground: @bg;
    }

    button {
        padding: 6px;
        color: @primary;
        horizonatal-align: 0.5;

        border: 2px 0px 2px 2px;
        border-radius: 4px 0px 0px 4px;
        border-color: @primary;
    }

    button selected normal {
        border: 2px 0px 2px 2px;
        border-color: @primary;
    }

    scrollbar {
        enabled: true;
    }
  '';

  #/////////////////////////////////////////

  #Configure Swappy
  #Create keybind: grim -g "$(slurp)" - | swappy -f -

  home.file.".config/swappy/config".text = ''
    [Default]
    save_dir=${config.home.homeDirectory}/Pictures
    save_filename_format=swappy-%Y%m%d-%H%M%S.png
    show_panel=false
    line_size=5
    text_size=20
    text_font=sans-serif
    paint_mode=brush
    early_exit=false
    fill_shape=false
  '';

  ## Enable hyprlock
  #programs.hyprlock = {
  #  enable = true;
  #  package = pkgs.hyprlock; # Ensure you have the correct package
  #  settings = {
  #    general = {
  #      disable_loading_bar = true;
  #      grace = 300;
  #      hide_cursor = true;
  #      no_fade_in = false;
  #    };
  #    auth = {
  #      pam = {
  #        enabled = true; # Ensure PAM is enabled
  #      };
  #    };
  #    background = [
  #      {
  #        blur_passes = 3;
  #        blur_size = 8;
  #      }
  #    ];
  #    input-field = [
  #      {
  #        size = "200, 50";
  #        position = "0, -80";
  #        monitor = "";
  #        dots_center = true;
  #        fade_on_empty = false;
  #        outline_thickness = 5;
  #        placeholder_text = "\"<span foreground=\"##cad3f5\">Password...</span>'\\";
  #        shadow_passes = 2;
  #      }
  #    ];
  #  };
  #};

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;

      preload = ["/etc/nixos/wallpapers/Tokyo2018_Everingham_SH_-9.jpg"];

      wallpaper = [
        "DP-2,/etc/nixos/wallpapers/Tokyo2018_Everingham_SH_-9.jpg"
        "DP-3,/etc/nixos/wallpapers/Tokyo2018_Everingham_SH_-9.jpg"
      ];
    };
  };

  systemd.user.services.hyprpaper.Unit.After = lib.mkForce "graphical-session.target";

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

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = null;
    package = pkgs.eza;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  # Set eza tokyonight coloscheme

  home.file."${config.xdg.configHome}/eza/theme.yml" = {
    source = "${pkgs.vimPlugins.tokyonight-nvim}/extras/eza/tokyonight.yml";
  };

  #programs.librewolf = {
  #  enable = true;
  #  settings = {
  #    "privacy.resistFingerprinting" = false;
  #    "privacy.resistFingerprinting.letterboxing" = true;
  #    "privacy.fingerprintingProtection" = true;
  #    "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";
  #    "privacy.trackingprotection.enabled" = true;
  #    "privacy.trackingprotection.excludelist" = "https://anthropic.com,https://api.anthropic.com,https://claude.ai";
  #    "webgl.disabled" = true;

  #    # Anonymize
  #    "general.settings.useragent.override" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0";
  #    intl.accept_languages = "en-US, en";
  #

  #    #Zoom 110%
  #    #"layout.css.devPixelsPerPx" = "1.1";

  #  };
  #};

  ##LibreWolf extensions
  ## setup tokyonight extension
  ## setup ublock origin
  ## setup canvasblocker
  ## setup privacy badger
  #home.file = {
  #  ".librewolf/profile/extensions/ublock@raymondhill.net.xpi".source = builtins.fetchurl {
  #    url = "https://addons.mozilla.org/firefox/downloads/file/4121906/ublock_origin-1.55.0.xpi";
  #    sha256 = "1cx5nzyjznhlyahlrb3pywanp7nk8qqkfvlr2wzqqlhbww1q0q8h";
  #  };
  #};

  ##Bitwarden, link is changing, needs update
  #home.file = {
  #  ".librewolf/profile/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi".source = builtins.fetchurl {
  #    url = "https://addons.mozilla.org/firefox/downloads/file/4440363/bitwarden_password_manager-2025.2.0.xpi";
  #    sha256 = "0x53sdqmz1nw1vwcs90g34aza69wrrzsrvah5x4215i6l9az7my4";
  #  };

  #};
  programs.librewolf = {
    enable = true;
    settings = {
      #Anti-fingerprinting loosened for camouflage
      "privacy.resistFingerprinting" = false;
      "privacy.resistFingerprinting.letterboxing" = false;
      "privacy.fingerprintingProtection" = true;
      "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";

      #Tracking protection
      "privacy.trackingprotection.enabled" = true;
      "privacy.trackingprotection.excludelist" = "https://anthropic.com,https://api.anthropic.com,https://claude.ai";

      #Spoofed user agent to mimic common Firefox on Windows
      #"general.useragent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0";
      #"general.useragent.override" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0";
      "general.appname.override" = "Netscape";
      "general.appversion.override" = "5.0 (Windows)";
      "general.platform.override" = "Win32";
      "general.oscpu.override" = "Windows NT 10.0";
      "general.buildID.override" = "20220101000000"; # optional

      #Language settings
      "intl.accept_languages" = "en-US, en";

      #WebGL enabled to reduce fingerprinting entropy (disabled = unique on Linux)
      "webgl.disabled" = false;

      #Avoid timezone mismatches
      "privacy.timezone.transition.enabled" = true;
      "privacy.resistFingerprinting.reduceTimerPrecision" = false;

      #Enable common DPI scaling (optional)
      "layout.css.devPixelsPerPx" = "1.0";

      #Fonts (optional): spoof or install common fonts manually for better blending
    };
  };

  home.file = {
    ".librewolf/profile/extensions/ublock@raymondhill.net.xpi".source = ublock;
    ".librewolf/profile/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi".source = bitwarden;
    ".librewolf/profile/extensions/CanvasBlocker@kkapsner.de.xpi".source = canvasblocker;
    ".librewolf/profile/extensions/jid1-MnnxcxisBPnSXQ@jetpack.xpi".source = privacybadger;
  };

  #TODO - Explore this
  #programs.lesspipe.enable = true;

  # Home packages

  home.packages = with pkgs; [
    #Niri
    swaybg
    xwayland-satellite

    # Packages
    delta # fancy git diff
    vlc
    git
    flameshot
    nomacs
    qpdf
    pdfcrack
    hashcat
    pdftk
    poppler_utils
    ghostscript
    libre
    rclone
    ntfs3g
    usbutils
    fastfetch
    lact
    mpv
    coolercontrol.coolercontrold
    coolercontrol.coolercontrol-gui
    dmenu
    ueberzug
    glance
    #librewolf-wayland

    # Hyprland
    pipewire
    wireplumber
    webcord # Discord is apparently a pain to run, so this is alternative
    hyprpicker
    grim # screenshots
    slurp # screenshots
    swappy # screenshots
    nerd-fonts.inconsolata
    nerd-fonts.fira-code
    adwaita-icon-theme
    bibata-cursors
    hyprsome
    clipse
    wezterm
    font-awesome_6
    qadwaitadecorations-qt6
    file
    nautilus
    xkbd

    # Neovim
    nixd # LSP server
    vimPlugins.nvim-lspconfig
    nixpkgs-fmt # Nix file formatter
    nixfmt-rfc-style # Nix file formatter
    alejandra # Nix file formatter

    # GPU
    mangohud
  ];
}
