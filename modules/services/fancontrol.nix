
# configuration.nix
{ config, pkgs, lib, ... }:

{
  # Define the fan control script content
  system.activationScripts.fanControlScript = lib.mkForce ''
    mkdir -p /etc/nixos/gpu-scripts
	
    cat << EOF > /etc/nixos/gpu-scripts/fancontrol.sh
	#!/bin/sh

	# Trap SIGTERM to handle shutdown properly
	trap "exit" SIGTERM

	# Define paths to necessary binaries
	NVIDIA_SETTINGS="/run/current-system/sw/bin/nvidia-settings"
	NVIDIA_SMI="/run/current-system/sw/bin/nvidia-smi"

	# Set the DISPLAY variable to ensure proper access to the X server
	export DISPLAY=:0
	export XAUTHORITY=/home/<your-username>/.Xauthority  # Replace <your-username> with the correct username

	# Enable manual fan control
	$NVIDIA_SETTINGS -a '[gpu:0]/GPUFanControlState=1' 2>> /var/log/fancontrol.log

	# Initialize variables
	CURRENTFANSPEED=0

	# Main loop to monitor temperature and adjust fan speed
	while true; do
	    # Get current GPU temperature
	    GPUTEMP=$($NVIDIA_SMI --query-gpu=temperature.gpu --format=csv,noheader)

	    # Determine the desired fan speed based on temperature thresholds
	    if [[ $GPUTEMP -gt 81 ]]; then
		DESIRED_FANSPEED=100
	    elif [[ $GPUTEMP -gt 65 ]]; then
		DESIRED_FANSPEED=90
	    elif [[ $GPUTEMP -gt 60 ]]; then
		DESIRED_FANSPEED=75
	    elif [[ $GPUTEMP -gt 50 ]]; then
		DESIRED_FANSPEED=65
	    elif [[ $GPUTEMP -gt 40 ]]; then
		DESIRED_FANSPEED=45
	    elif [[ $GPUTEMP -gt 15 ]]; then
		DESIRED_FANSPEED=30
	    else
		DESIRED_FANSPEED=0
	    fi

	    # Only update the fan speed if it differs from the current fan speed
	    if [[ $DESIRED_FANSPEED -ne $CURRENTFANSPEED ]]; then
		$NVIDIA_SETTINGS -a "[fan:0]/GPUTargetFanSpeed=$DESIRED_FANSPEED" \
				 -a "[fan:1]/GPUTargetFanSpeed=$DESIRED_FANSPEED" 2>> /var/log/fancontrol.log
		CURRENTFANSPEED=$DESIRED_FANSPEED
	    fi

	    # Sleep for 2 seconds before checking again
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
