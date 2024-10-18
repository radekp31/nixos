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
    unstable.vlc
    git
    openssh
    ];
  
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


  #Enable NVIM
  programs.neovim = {
	enable = true;
	viAlias = true;
	vimAlias = true;
	vimdiffAlias = true;

#  extraLuaConfig = ''
#  	 ${builtins.readFile ./nvim/options.lua}
#  '';

  extraPackages = with pkgs; [
      lua-language-server
#      rnix-lsp

      xclip
      wl-clipboard
    ];
  };

  # backup nixos config to git


 systemd.user.services.git-backup = {
    Unit = {
      Description = "NixOS config backup to git";  # The correct way to define the description
    };
    Service = {
      Type = "oneshot";  # Run once and exit
      ExecStart = "${pkgs.bash}/bin/bash -c /home/radekp/.dotfiles/backup.sh";  # Run the script
      Environment = [
        "GIT=${pkgs.git}/bin/git"  # Make git available
	"SSH=${pkgs.openssh}/bin/ssh"  # Add ssh to the environment
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];  # Automatically start on user login
    };
  };


}
