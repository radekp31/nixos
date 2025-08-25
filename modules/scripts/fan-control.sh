#Source: https://github.com/JGtHb/NVFanControl 

#By default, Nvidia GPUs manage the fan speed with the firmware. To change this setting to allow this script to control your fan speed, use the below command. Do not forget to revert this command if disabling this fan control script.
#
#sudo nvidia-settings -a gpufancontrolstate=1


{ pkgs, ... }:

{

systemd.timers.NVFanControl = {
  wantedBy = [ "timers.target" ];
   timerConfig = {
      OnBootSec = "1s";
      OnUnitActiveSec = "1s";
    };
};

systemd.services.NVFanControl = {
    enable = true;
    description = "NVIDIA Fan Control Bash Script";
    serviceConfig = { Type = "oneshot";  };
    path = [pkgs.gawk]; #used for sine wave curve calc
    wantedBy = [ "default.target" ];
    partOf = ["default.target" ];
    script = ''
    declare -i gpuTemp
    declare -i gpuTempFloor
    declare -i gpuTempCeiling
    declare -i targetFanSpeed
    declare -i fallbackFanSpeed

    gpuTemp=$(/run/current-system/sw/bin/nvidia-settings -q gpucoretemp -c 0 2> /dev/null | grep -Po "(?<=: )[0-9]+(?=\.)")
    gpuTempFloor=$((gpuTemp<50 ? 50 : gpuTemp)) #minimum bound of fan curve
    gpuTempCeiling=$((gpuTempFloor>80 ? 80 : gpuTempFloor)) #maximum bound of fan curve
    targetFanSpeed=$(gawk -v temp=$gpuTempCeiling 'BEGIN{printf "%.0f", 35 * sin((temp-1.5)/10)+65}') #calculate the target fan speed based on a sine curve from x=50 to x=80. round to the nearest whole number.
    finalFanSpeed=$((targetFanSpeed>=30 && targetFanSpeed<=100 ? targetFanSpeed : 100)) #if a valid fan target wasn't calculated, turn fans on 100% as a safety measure

    echo "Current Temp: $gpuTemp | Target Fan Speed: $finalFanSpeed"
    /run/current-system/sw/bin/nvidia-settings -a GPUTargetFanSpeed="$finalFanSpeed" -c 0
    '';
  };
}
