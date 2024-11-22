{ pkgs, lib, config, ... }:

let 
        unstable = import <nixpkgs> { };
	font = "MesloLGL Nerd Font"; #default monospace
in

{

  #Let Home Manager install and manage itself
  programs.home-manager.enable = true;
  
  # User settings
  home.username = "radekp";
  home.homeDirectory = "/home/radekp";
  home.stateVersion = "24.05";


# Alacritty overwrites the env vars, put them into alacritty.toml below
#  home.sessionVariables = {
#	EDITOR = "nvim";
#	VISUAL = "nvim";
#  };


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
	DP-4 = [
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
	split_ratio =  0.52;
	borderless_monocle = true;
	gapless_monocle = true;
  };

  xsession.windowManager.bspwm.rules = {
	"Gimp" = {
          desktop="^8";
	  state="floating";
          follow=true;
	};
	"Screenkey" = {
	  manage=true;
	  };

  };

  # Enable sxhkd
  services.sxhkd.enable = true;

  services.sxhkd.keybindings = {
  # wm independent hotkeys
  "super + Return" = "alacritty";
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
  

  #Setup and configure git
  programs.git = {
	enable = true;
	userName = "Radek Polasek";
	userEmail = "polasek.31@seznam.cz";
	extraConfig = {
		init.defaultBranch = "main";
         };
  };

  #Bash is needed for XDG vars - needs testing
  programs.bash = {
  enable = true;
  };
  xdg.enable = true ;

  #Enable Alacritty
  programs.alacritty.enable = true;

  home.file.".config/alacritty/alacritty.toml" = {
    text = ''
	[general]
	import = ["${pkgs.alacritty-theme}/tokyo_night.toml"]

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
  programs.neovim = {
	enable = false;
	viAlias = true;
	vimAlias = true;
	vimdiffAlias = true;
	plugins	= with pkgs.vimPlugins; [
		tokyonight-nvim
	];
	extraConfig = ''
		au VimLeave * :!clear
		#colorscheme tokyonight-night"
	'';

        extraPackages = with pkgs; [
        	lua-language-server
      		#rnix-lsp

      		xclip
      		wl-clipboard
    	];
  };
}
