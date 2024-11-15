
# configuration.nix
{ config, pkgs, lib, ... }:

{
  # Define the fan control script content
  system.activationScripts.fanControlScript = lib.mkForce ''
    mkdir -p /etc/nixos/gpu-scripts
	   
	trap "exit" SIGTERM

	    /run/current-system/sw/bin/nvidia-settings -a '[gpu:0]/GPUFanControlState=1'

	CURRENTFANSPEED=0

	    while true; do

	    GPUTEMP=$(/run/current-system/sw/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)

		if [[ $GPUTEMP -gt 15 ]] && [[ CURRENTFANSPEED -lt 30 ]]; then
		    CURRENTFANSPEED=30 && /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=30' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=30';
		fi

		if [[ $GPUTEMP -gt 40 ]] && [[ CURRENTFANSPEED -lt 45 ]]; then
		    CURRENTFANSPEED=45 && /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=45' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=45';
		fi

		if [[ $GPUTEMP -gt 50 ]] && [[ CURRENTFANSPEED -lt 65 ]]; then
		    CURRENTFANSPEED=65 && /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=65' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=65';
		fi

		if [[ $GPUTEMP -gt 60 ]] && [[ CURRENTFANSPEED -lt 75 ]]; then
		    CURRENTFANSPEED=75 && /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=75' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=75';
		fi

		if [[ $GPUTEMP -gt 65 ]] && [[ CURRENTFANSPEED -lt 90 ]]; then
		    CURRENTFANSPEED=90 && /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=90' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=90';
		fi

		if [[ $GPUTEMP -gt 81 ]] && [[ CURRENTFANSPEED -lt 100 ]]; then
		    CURRENTFANSPEED=100 && /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=100' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=100';
		fi

		sleep 2
	    done
   EOF
    chmod 755 /etc/nixos/gpu-scripts/fancontrol.sh
  '';

  # Define the fan control service
  systemd.services.fanControlService = {
    description = "GPU Fan Control Service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = ["/run/current-system/sw/bin/nvidia-smi" "/run/current-system/sw/bin/nvidia-settings"];

    # Run the copied script in /etc
    serviceConfig.ExecStart = [ "/etc/nixos/gpu-scripts/fancontrol.sh" ];
    serviceConfig.User = "root";
    serviceConfig.Restart = "always";
    serviceConfig.RestartSec = 5;
    serviceConfig.Environment = [
    	"DISPLAY=:0"
    	"LD_LIBRARY_PATH=${pkgs.libGL}/lib"
    ];
  };
}
