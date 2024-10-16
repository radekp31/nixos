{ pkgs, lib, config, ... }:

let 
        unstable = import <nixpkgs> { };
	
in

{
  # User settings
  home.username = "radekp";
  home.homeDirectory = "/home/radekp";
  home.stateVersion = "24.05";

  # Home packages
  home.packages = with pkgs; [
    unstable.neovim
    unstable.vlc
    git
    ];
  
  # Set wallpaper
  xsession.profileExtra = ''
    # Ensure D-Bus session is initialized
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
      export $(dbus-launch)
    fi

  # Set the wallpaper using gsettings
  gsettings set org.gnome.desktop.background picture-uri 'file:///home/radekp/.config/wallpapers/nix-wallpaper-binary-black.png'
    '';

  # Run login scripts
  home.activation = {
      test = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # run scripts here
      '';
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
}

