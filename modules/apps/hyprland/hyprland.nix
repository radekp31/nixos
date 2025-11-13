{pkgs, ...}: {
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true;
  # Set default session to Hyprland+uswm
  services.displayManager.defaultSession = "hyprland-uwsm";
  services.xserver.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --time --time-format '%I:%M %p | %a -- %h | %F' --cmd Hyprland";
  };
  services.xserver.desktopManager.plasma5.enable = true;

  # Required if using Nvidia card
  #services.xserver.videoDrivers = [ "nvidia" ];
  #hardware.graphics.enable = true; # hardware.opengl.enable on older versions
  #hardware.nvidia.modesetting.enable = true;

  xdg.portal = {
    enable = true;
  };

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
}
# End of Hyprland attempt

