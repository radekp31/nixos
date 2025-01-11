{
  pkgs,
  lib,
  config,
  ...
}:

let
  unstable = import <nixpkgs> { };
in

{

  #Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Home Manager settings
  home.username = "radekp";
  home.homeDirectory = "/home/radekp";
  home.stateVersion = "24.05";
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

  #  home.activation.connectOneDrive = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #  # Command to run after user login
  #  fusermount -uz /media/WDRED/OneDrive #unmount remote, just in case its broken
  #  rclone cmount --vfs-cache-mode writes onedrive: /media/WDRED/OneDrive #mount the remote
  #'';

  # Alacritty overwrites the env vars, put them into alacritty.toml below
  #  home.sessionVariables = {
  #	EDITOR = "nvim";
  #	VISUAL = "nvim";
  #  };

  # Hyprland attempt
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      #decoration = {
      #  shadow_offset = "0 5";
      #  "col.shadow" = "rgba(00000099)";
      #};

      "$mod" = "SUPER";

      bind = [
        # Keybindings
        "$mod, F, fullscreen"
        "$mod, Return, exec, kitty"
        "$mod, grave, exec, grim -g \"$(slurp)\" - | swappy -f -"
        "$mod, space, exec, rofi -show combi"
        "$mod, G, exec, rofi -show games "
        "$mod, LEFT, workspace, -1"
        "$mod, RIGHT, workspace, +1"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, P, exec, /etc/nixos/modules/scripts/game-mode.sh"
      ];
      monitor = [
        #Monitor setup
        "DP-2, 2560x1440@144, 0x0, auto"
        "DP-3, 1680x1050@60, -1680x0, auto"
      ];
    };

    extraConfig = '''';
    #settings = {
    #  decoration = {
    #    shadow_offset = 0.5;
    #	"col.shadow" = "rgba(00000099)";
    #  };
    #
    #  "$mod" = "SUPER";
    #
    #  bindm = [
    #    "$mod, mouse:272, moveWindow"
    #	"$mod, mouse:273, resizeWindow"
    #	"$mod ALT, mouse:272, resizeWindow"
    #  ];

    systemd = {
      enable = true;
      extraCommands = [
        "systemctl --user start hyprland-session.target"
      ];
      variables = [
        "--all" # hope this works
        #"DISPLAY"
        #"HYPRLAND_INSTANCE_SIGNATURE"
        #"WAYLAND_DISPLAY"
        #"XDG_CURRENT_DESKTOP"
      ];
    };
  };

  home.file.".local/share/wayland-sessions/hyprland.desktop".text = ''
    [Desktop Entry]
    Name=Hyprland
    Exec=Hyprland
    Type=Application
  '';

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    #font-family: Source Code Pro;
    style = ''
              *     {
                    font-family: "Incosolata Nerd Font";
                    font-size: 13px;
            	}

            	#waybar {
            	    background-color: #16191C;
            	    color: #AAB2BF;
            	}

            	button {
            	    box-shadow: inset 0 -3px transparent;
            	    border: none;
            	    border-radius: 0;
            	    padding: 0 5px;
            	}

            	#workspaces button {
            	    background-color: #5f676a;
            	    color: #ffffff;
            	}

            	#workspaces button:hover {
            	    background: rgba(0,0,0,0.2);
            	}

            	#workspaces button.focused {
            	    background-color: #285577;
            	}

            	#workspaces button.urgent {
            	    background-color: #900000;
            	}

            	#workspaces button.active {
            	    background-color: #285577;
            	}
      	/* Default keyboard state styling */
      	#keyboard-state {
      	    color: #16191C;
      	    background-color: #16191C;
      	    /*padding: 5px; */
      	    /*border-radius: 5px; */
      	}
      	
      	/* When Caps Lock is enabled (unlocked but active) */
      	#keyboard-state label.capslock {
      	    color: #AAB2BF; /* Yellow text for active Caps Lock */
      	    background-color: #16191C; /* Optional background change */
      	    min-width: 100px; /* Set a fixed width */
          	    /*display: inline-block; */ /* Ensure the element respects the fixed width */
          	    /*text-align: center; */ /* Optional: center the text inside */
      	}
      	
      	/* When Caps Lock is locked */
      	#keyboard-state label.capslock.locked {
      	    color: #AAB2BF; /* Red text for locked Caps Lock */
      	    background-color: #285577; /* Optional background change */
      	    min-width: 100px; /* Set a fixed width */
          	    /*display: inline-block; */ /* Ensure the element respects the fixed width */
          	    /*text-align: center; */ /* Optional: center the text inside */
      	}
            	#clock,
            	#battery,
            	#cpu,
            	#memory,
            	#pulseaudio,
            	#tray,
            	#mode,
            	#idle_inhibitor,
            	#window,
            	#workspaces {
            	    margin: 0 5px;
            	}


            	.modules-left > widget:first-child > #workspaces {
            	    margin-left: 0;
            	}


            	.modules-right > widget:last-child > #workspaces {
            	    margin-right: 0;
            	}

            	@keyframes blink {
            	    to {
            		background-color: #ffffff;
            		color: #000000;
            	    }
            	}

            	label:focus {
            	    background-color: #000000;
            	}

            	#tray > .passive {
            	    -gtk-icon-effect: dim;
            	}

            	#tray > .needs-attention {
            	    -gtk-icon-effect: highlight;
            	    background-color: #eb4d4b;
            	}

    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 5;
        height = 30;
        #output = [ "DP-2" ];
        output = [ "*" ];
        modules-left = [ "hyprland/workspaces" ]; # put back sway/mode if needed
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "keyboard-state"
          "disk"
          "cpu"
          "memory"
          "pulseaudio"
          "clock"
          "custom/power"
        ];

        # modules-left
        "sway/mode" = {
          format = "{}";
        };
        # Modules configuration
        "hyprland/workspaces" = {
          persistent-workspaces = {
            "*" = 5; # 5 workspaces by default on every monitor
          };
        };
        # modules-center
        "hyprland/window" = {
          format = "{title}";
        };

        # modules-right
        #"keyboard-state" = {
        #  numlock = true;
        #  capslock = true;
        #  format = "{name} {icon}";
        #  format-icons = {
        #    locked = " ";
        #    unlocked = " ";
        #  };
        #};
        "keyboard-state" = {
          #numlock = true;
          capslock = true;
          keyboard-state = {
            format = "{name}";
            #format-capslock = "Caps Lock On";
            format-icons = {
              capslock = "Caps";
            };
          };
        };
        "disk" = {
          interval = 30;
          format = "/ {percentage_used}% ";
        };
        "cpu" = {
          interval = 10;
          format = "CPU: {usage}%";
        };
        "memory" = {
          interval = 10;
          format = "RAM: {percentage}%";
        };
        "pulseaudio" = {
          format = "{volume}%";
        };
        "clock" = {
          format = "{:%Y/%m/%d %H:%M}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              today = "<span color='#ff6699'><b>{}</b></span>";
            };
          };
        };
        "custom/power" = {
          format = "⏻ ";
          tooltip = false;
          menu = "on-click";
          menu-file = "$HOME/.config/waybar/power_menu.xml"; # Menu file in resources folder
          menu-actions = {
            shutdown = "shutdown";
            reboot = "reboot";
            suspend = "systemctl suspend";
            hibernate = "systemctl hibernate";
          };
        };
      };
    };
  };

  # Enable Hyprlock
  #programs.hyprlock = {
  #  enable = false;
  #  settings = {
  #    general = {
  #      disable_loading_bar = true;
  #      grace = 300;
  #      hide_cursor = true;
  #      no_fade_in = false;
  #    };

  #    background = [
  #      {
  #        path = "screenshot";
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
  #        font_color = "rgb(202, 211, 245)";
  #        inner_color = "rgb(91, 96, 120)";
  #        outer_color = "rgb(24, 25, 38)";
  #        outline_thickness = 5;
  #        placeholder_text = "\"<span foreground=\"##cad3f5\">Password...</span>'\\";
  #        shadow_passes = 2;
  #      }
  #    ];
  #  };
  #};

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

  # Configure Rofi app launcher
  programs.rofi = {
    enable = true;
    cycle = true;
    font = "Inconsolata";
    location = "center";
    plugins = [
      pkgs.rofi-calc
      pkgs.rofi-games
      pkgs.rofi-wayland
    ];
    terminal = "\${pkgs.kitty}/bin/kitty";
    theme = "tokyo-night.rasi";
  };

  # Rofi TokyoNight theme
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

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;

      preload = [ "/home/radekp/Pictures/Tokyo2018_Everingham_SH_-9.jpg" ];

      wallpaper = [
        "DP-2,/home/radekp/Pictures/Tokyo2018_Everingham_SH_-9.jpg"
        "DP-3,/home/radekp/Pictures/Tokyo2018_Everingham_SH_-9.jpg"
      ];
    };
  };

  programs.wofi = {
    enable = true;
    settings = {
      location = "center";
      allow_markup = true;
      width = 250;
    };
    style = ''
      * {
        font-family: monospace;
      }

      window {
        background-color: #1a1b26;
      }
    '';
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    #flavors = {
    #  This is some kind of variation of themes - there is tokyonight available - get it!
    #};
    keymap = {
      input.keymap = [
        {
          exec = "close";
          on = [ "<C-q>" ];
        }
        {
          exec = "close --submit";
          on = [ "<Enter>" ];
        }
        {
          exec = "escape";
          on = [ "<Esc>" ];
        }
        {
          exec = "backspace";
          on = [ "<Backspace>" ];
        }
      ];
      manager.keymap = [
        {
          exec = "escape";
          on = [ "<Esc>" ];
        }
        {
          exec = "quit";
          on = [ "q" ];
        }
        {
          exec = "close";
          on = [ "<C-q>" ];
        }
      ];
    };
    settings = {
      log = {
        enabled = false;
      };
      manager = {
        show_hidden = false;
        sort_by = "modified";
        sort_dir_first = true;
      };
    };
  };

  #Hyprland - kitty is used by default
  programs.kitty = {
    enable = true;
    #themeFile = "${pkgs.kitty-themes}/share/kitty-themes/themes/tokyo_night_night.conf";
    extraConfig = ''
      include ${pkgs.kitty-themes}/share/kitty-themes/themes/tokyo_night_night.conf
    '';
    environment = {

      "TERM" = "xterm-256color";
      "EDITOR" = "nvim";
      "VISUAL" = "nvim";
      "BAT_THEME" = "ansi";
      "MANPAGER" = "nvim +Man!";
      "PATH" = "${pkgs.kitty}/bin:$PATH";
      # #WaybarLife
      "WAYBAR_LOG_LEVEL" = "debug waybar";
      "WAYLAND_DISPLAY" = "wayland-1";
      #Cursor
      "XCURSOR_THEME" = "${pkgs.bibata-cursors}/share/icons/Bibata-Modern-ice/cursor.theme";
      "XCURSOR_SIZE" = "24";
      #Wayland life
      "DISPLAY" = ":0";
      "XAUTHORITY" = "/run/user/1000/.Xauthority";
      #"QT_QPA_PLATFORM" = "xcb"; #OneDrivegui needs this  
      #"AQ_DRM_DEVICES" = "/dev/dri/card0";
      #"WLR_NO_HARDWARE_CURSORS" = "1";
      #"GBM_BACKEND" = "/run/opengl-driver/lib/dri/nvidia_gbm.so";
      # Set Wayland-related variables

      #"WAYLAND_DISPLAY" = ":1"; # included in wayland.windowManager.hyprland.systemd.enable
      "XDG_SESSION_TYPE" = "wayland";
      #"XDG_CURRENT_DESKTOP" = "Hyprland"; # included in wayland.windowManager.hyprland.systemd.enable
      "MOZ_ENABLE_WAYLAND" = "1"; # Enable Wayland for Firefox, if applicable
      #"QT_QPA_PLATFORM" = "wayland"; # Use Wayland for Qt apps
    };
    font = {
      package = pkgs.nerd-fonts.inconsolata;
      name = "Inconsolata";
      size = 14.0;
    };
    keybindings = {
      "ctrl+c" = "copy_or_interrupt";
    };
    settings = {
      scrollback_lines = 10000;
      enable_audio_bell = false;
      update_check_interval = 0;
    };
    shellIntegration = {
      enableBashIntegration = true;
      enableZshIntegration = true;
      mode = "no-rc";
    };
  };

  # Home packages
  home.packages = with pkgs; [
    unstable.vlc
    git
    alacritty
    alacritty-theme
    flameshot
    nomacs
    qpdf
    pdfcrack
    hashcat
    pdftk
    poppler_utils
    ghostscript
    john
    johnny
    libre
    ventoy-full
    rclone
    ntfs3g

    mpv

    # Hyprland
    kitty-themes
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
    hyprlock # Custom package hyprlock-git
    font-awesome_6
    onedrive
    onedrivegui
    qadwaitadecorations-qt6

    # Neovim
    nixd # LSP server
    vimPlugins.nvim-lspconfig
    nixpkgs-fmt # Nix file formatter
    nixfmt-rfc-style # Nix file formatter
    alejandra # Nix file formatter

    # GPU
    mangohud


  ];

  # Setup bspwm

  xsession.windowManager.bspwm.enable = true;
  xsession.windowManager.bspwm.extraConfigEarly = ''
    	# Start sxhkd if it is not running
    	pgrep -x sxhkd > /dev/null || sxhkd &

    	# Wait for a bit before starting Polybar to ensure services are ready
    	sleep 1

    	#Apply nvidia-settings profile
    	nvidia-settings -l

    	# Kill any existing Polybar instances before starting a new one
    	killall -q polybar
    	while pgrep -x polybar >/dev/null; do sleep 1; done

    	# Start Polybar
    	polybar -c ~/.config/polybar/example/config.ini example > /tmp/polybar.log 2>&1 &
    	

    	# Set wallpaper
    	feh --bg-center /etc/nixos/wallpapers/nix-wallpaper-binary-black.jpg

            # Set cursor to pointer
    	xsetroot -cursor_name left_ptr &
  '';
  xsession.windowManager.bspwm.extraConfig = ''
    	
            sudo /run/current-system/sw/bin/nvidia-settings -c :0 -a '[gpu:0]/GPUFanControlState=1'
            sudo /run/current-system/sw/bin/nvidia-settings -c :0 -a GPUTargetFanSpeed=35
            sudo /run/current-system/sw/bin/nvidia-settings -a "DigitalVibrance=0"
            ##sudo /run/current-system/sw/bin/nvidia-settings -l
  '';

  xsession.windowManager.bspwm.monitors = {
    DP-2 = [
      "I"
      "II"
      "III"
      "IV"
      "V"
      "VI"
      "VII"
      "VIII"
      "IX"
      "X"
    ];

  };

  xsession.windowManager.bspwm.settings = {

    border_width = 2;
    window_gap = 12;
    split_ratio = 0.52;
    borderless_monocle = true;
    gapless_monocle = true;
  };

  xsession.windowManager.bspwm.rules = {
    "Gimp" = {
      desktop = "^8";
      state = "floating";
      follow = true;
    };
    "Screenkey" = {
      manage = true;
    };
  };

  # Enable sxhkd
  services.sxhkd.enable = true;

  services.sxhkd.keybindings = {
    # wm independent hotkeys
    "super + Return" = "kitty";
    "super + space" = "rofi -show combi";
    "alt + F1" = "rofi -show window";
    "alt + F2" = "rofi -show run";
    "alt + F4" = "rofi -show power-menu -modi power-menu:rofi-power-menu";
    "super + Escape" = "pkill -USR1 -x sxhkd";
    "super + e" = "alacritty --command yazi";
    "alt + Escape" = "betterlockscreen -l dim";
    "Print" = "flameshot gui";
    "Shift + Print" = "/etc/nixos/modules/scripts/screenshot.sh";

    # bspwm hotkeys
    "super + f" = "bspc node -t ~fullscreen";
    "super + alt + q" = "bspc quit";
    "super + alt + r" = "bspc wm -r";
    "super + w" = "bspc node -c";
    "super + shift + w" = "bspc node -k";
    "super + m" = "bspc desktop -l next";
    "super + y" = "bspc node newest.marked.local -n newest.!automatic.local";
    "super + g" = "bspc node -s biggest.window";

    # state/flags
    "super + t" = "bspc node -t tiled";
    "super + shift + t" = "bspc node -t pseudo_tiled";
    "super + s" = "bspc node -t floating";
    #  "super + f" = "bspc node -t fullscreen";
    "super + ctrl + m" = "bspc node -g marked";
    "super + ctrl + x" = "bspc node -g locked";
    "super + ctrl + y" = "bspc node -g sticky";
    "super + ctrl + z" = "bspc node -g private";

    # focus/swap
    "super + h" = "bspc node -f west";
    "super + j" = "bspc node -f south";
    "super + k" = "bspc node -f north";
    "super + l" = "bspc node -f east";
    "super + shift + h" = "bspc node -s west";
    "super + shift + j" = "bspc node -s south";
    "super + shift + k" = "bspc node -s north";
    "super + shift + l" = "bspc node -s east";
    "super + p" = "bspc node -f @parent";
    "super + b" = "bspc node -f @brother";
    "super + comma" = "bspc node -f @first";
    "super + period" = "bspc node -f @second";
    "super + c" = "bspc node -f next.local.!hidden.window";
    "super + shift + c" = "bspc node -f prev.local.!hidden.window";
    "super + bracketleft" = "bspc desktop -f prev.local";
    "super + bracketright" = "bspc desktop -f next.local";
    "super + grave" = "bspc node -f last";
    "super + Tab" = "bspc desktop -f last";
    "super + o" = "bspc wm -h off; bspc node older -f; bspc wm -h on";
    "super + i" = "bspc wm -h off; bspc node newer -f; bspc wm -h on";
    "super + 1" = "bspc desktop -f ^1";
    "super + {_,shift + }{1-9,0}" = "bspc {desktop -f, node -d} '^{1-9,10}' --follow";
    #"super + shift + <x>" = "bspc node -d ^<x>"; per workspace binding

    # preselect
    "super + ctrl + h" = "bspc node -p west";
    "super + ctrl + j" = "bspc node -p south";
    "super + ctrl + k" = "bspc node -p north";
    "super + ctrl + l" = "bspc node -p east";
    "super + ctrl + 1" = "bspc node -o 0.1";
    "super + ctrl + 2" = "bspc node -o 0.2";
    "super + ctrl + 3" = "bspc node -o 0.3";
    "super + ctrl + 4" = "bspc node -o 0.4";
    "super + ctrl + 5" = "bspc node -o 0.5";
    "super + ctrl + 6" = "bspc node -o 0.6";
    "super + ctrl + 7" = "bspc node -o 0.7";
    "super + ctrl + 8" = "bspc node -o 0.8";
    "super + ctrl + 9" = "bspc node -o 0.9";
    "super + ctrl + space" = "bspc node -p cancel";
    "super + ctrl + shift + space" = "bspc query -N -d | xargs -I id -n 1 bspc node id -p cancel";

    # move/resize
    "super + alt + h" = "bspc node -z left -20 0";
    "super + alt + j" = "bspc node -z bottom 0 20";
    "super + alt + k" = "bspc node -z top 0 -20";
    "super + alt + l" = "bspc node -z right 20 0";
    "super + alt + shift + h" = "bspc node -z right -20 0";
    "super + alt + shift + j" = "bspc node -z top 0 20";
    "super + alt + shift + k" = "bspc node -z bottom 0 -20";
    "super + alt + shift + l" = "bspc node -z left 20 0";
    "super + Left" = "bspc node -v -20 0";
    "super + Down" = "bspc node -v 0 20";
    "super + Up" = "bspc node -v 0 -20";
    "super + Right" = "bspc node -v 20 0";
  };

  home.file.".config/polybar/example/config.ini".text = ''
    [bar/example]
    width = 100%
    height = 24pt
    radius = 6

    background = #282A2E
    foreground = #C5C8C6

    line-size = 3pt

    border-size = 4pt
    border-color = #00000000

    padding-left = 0
    padding-right = 1

    module-margin = 1

    separator = |
    separator-foreground = #707880

    font-0 = monospace;2

    modules-left = xworkspaces xwindow
    modules-right = filesystem pulseaudio xkeyboard memory cpu wlan eth date

    cursor-click = pointer
    cursor-scroll = ns-resize

    enable-ipc = true

    [module/systray]
    type = internal/tray

    format-margin = 8pt
    tray-spacing = 16pt

    [module/xworkspaces]
    type = internal/xworkspaces

    label-active = %name%
    label-active-background = #373B41
    label-active-underline = #F0C674
    label-active-padding = 1

    label-occupied = %name%
    label-occupied-padding = 1

    label-urgent = %name%
    label-urgent-background = #A54242
    label-urgent-padding = 1

    label-empty = %name%
    label-empty-foreground = #707880
    label-empty-padding = 1

    [module/xwindow]
    type = internal/xwindow
    label = %title:0:60:...%

    [module/filesystem]
    type = internal/fs
    interval = 25

    mount-0 = /

    label-mounted = %{F#F0C674}%mountpoint%%{F-} %percentage_used%%

    label-unmounted = %mountpoint% not mounted
    label-unmounted-foreground = #707880

    [module/pulseaudio]
    type = internal/pulseaudio

    format-volume-prefix = "VOL "
    format-volume-prefix-foreground = #F0C674
    format-volume = <label-volume>

    label-volume = %percentage%%

    label-muted = muted
    label-muted-foreground = #707880

    [module/xkeyboard]
    type = internal/xkeyboard
    blacklist-0 = num lock

    label-layout = %layout%
    label-layout-foreground = #F0C674

    label-indicator-padding = 2
    label-indicator-margin = 1
    label-indicator-foreground = #282A2E
    label-indicator-background = #8ABEB7

    [module/memory]
    type = internal/memory
    interval = 2
    format-prefix = "RAM "
    format-prefix-foreground = #F0C674
    label = %percentage_used:2%%

    [module/cpu]
    type = internal/cpu
    interval = 2
    format-prefix = "CPU "
    format-prefix-foreground = #F0C674
    label = %percentage:2%%

    [network-base]
    type = internal/network
    interval = 5
    format-connected = <label-connected>
    format-disconnected = <label-disconnected>
    label-disconnected = %{F#F0C674}%ifname%%{F#707880} disconnected

    [module/wlan]
    inherit = network-base
    interface-type = wireless
    label-connected = %{F#F0C674}%ifname%%{F-} %essid% %local_ip%

    [module/eth]
    inherit = network-base
    interface-type = wired
    label-connected = %{F#F0C674}%ifname%%{F-} %local_ip%

    [module/date]
    type = internal/date
    interval = 1

    date = %H:%M
    date-alt = %Y-%m-%d %H:%M:%S

    label = %date%
    label-foreground = #F0C674

    [settings]
    screenchange-reload = true
    pseudo-transparency = true
  '';

  #Setup and configure git
  programs.git = {
    enable = true;
    userName = "Radek Polasek";
    userEmail = "polasek.31@seznam.cz";
    extraConfig = {
      init.defaultBranch = "main";
      safe.directory = "/etc/nixos";
    };
  };

  #Bash is needed for XDG vars - needs testing
  programs.bash = {
    enable = true;
  };
  xdg = {
    enable = true;
  };
  #Enable Alacritty
  programs.alacritty.enable = true;

  home.file.".config/alacritty/alacritty.toml" = {
    text = ''
              [general]
      	import = ["${pkgs.alacritty-theme}/tokyo-night.toml"]

      	[font]
      	size = 13.0
      	#normal = {family = "Hack", style = "Regular"}
      	#bold = {family = "Hack", style = "Bold"}
      	#italic = {family = "Hack", style = "Italic"}
      	#bold_italic = {family = "Hack", style = "Bold Italic"}
        
      	[cursor]
      	style = { shape = "Underline", blinking = "Always" }

      	[mouse]
      	bindings = [
      	{ mouse = "Right", mods = "Shift", action = "Copy" },
      	{ mouse = "Right", action = "Paste" },
      	]

      	[selection]
      	semantic_escape_chars = ",│`|:\"' ()[]{}<>\t"
      	save_to_clipboard = true

      	[env]
      	TERM = "xterm-256color"
      	EDITOR = "nvim"
      	VISUAL = "nvim"
      	BAT_THEME = "ansi"
      	MANPAGER = "nvim +Man!"
      	
      	# Set Wayland-related variables
              
      	#WAYLAND_DISPLAY = ":1" # included in wayland.windowManager.hyprland.systemd.enable
      	#XDG_SESSION_TYPE = "wayland"
        	#XDG_CURRENT_DESKTOP = "Hyprland" # included in wayland.windowManager.hyprland.systemd.enable
      	MOZ_ENABLE_WAYLAND = "1" # Enable Wayland for Firefox, if applicable
      	QT_QPA_PLATFORM = "wayland" # Use Wayland for Qt apps

      	[colors.primary]
      	
      	background = '#1a1b26'
      	foreground = '#a9b1d6'
      	
      	# Normal colors
      	#[colors.normal]
      	#black   = '#32344a'
      	#red     = '#f7768e'
      	#green   = '#9ece6a'
      	#yellow  = '#e0af68'
      	#blue    = '#7aa2f7'
      	#magenta = '#ad8ee6'
      	#cyan    = '#449dab'
      	#white   = '#787c99'
      	#
      	## Bright colors
      	#[colors.bright]
      	#black   = '#444b6a'
      	#red     = '#ff7a93'
      	#green   = '#b9f27c'
      	#yellow  = '#ff9e64'
      	#blue    = '#7da6ff'
      	#magenta = '#bb9af7'
      	#cyan    = '#0db9d7'
      	#white   = '#acb0d0'
    '';
  };

  #Enable NVIM
  #Enable NVIM
  programs.neovim = {
    enable = false;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = [
      # Plugin 1: nvim-colorizer-lua
      {
        plugin = pkgs.vimPlugins.tokyonight-nvim;
      }

      # Plugin 2: nvim-treesitter
      {
        plugin = pkgs.vimPlugins.nvim-lspconfig;
      }

      # Plugin 3: telescope.nvim
      {
        plugin = pkgs.vimPlugins.telescope-nvim;
        config = ''
                        packadd! telescope.nvim
                        lua << END
                require('telescope').setup{
            defaults = {
              mappings = {
                i = {
                  ["<C-n>"] = require('telescope.a
                  ["<C-p>"] = require('telescope.actions').cycle_history_prev,
                },
              },
            }
          }
          END
        '';
      }
    ];

    extraConfig = ''
                  	" Enable Tokyo Night color scheme
                  	colorscheme tokyonight-night

                  	" Enable row numbers
                          set number
                          set relativenumber

                      " Clear screen after exit
                  	lua vim.api.nvim_create_autocmd("VimLeavePre", { command = "silent !clear" })
      		
      		" Configure Lsp server
      		lua << EOF
      local nvim_lsp = require("lspconfig")
      nvim_lsp.nixd.setup({
         cmd = { "nixd" },
         settings = {
            nixd = {
               nixpkgs = {
                  expr = "import <nixpkgs> { }",
      	 },
               formatting = {
                  command = { "nixfmt" },
               },
      	 options = {
      	   nixos = {
      	     expr = "(builtins.getFlake \"/home/lyc/flakes\").nixosConfigurations.adrastea.options"
      	   },
      	 },
            },
         },
      })
      EOF
    '';

    extraPackages = with pkgs; [
      nixd
      lua-language-server
      xclip
      wl-clipboard
    ];
  };

}
