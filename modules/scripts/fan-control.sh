#!/run/current-system/sw/bin/bash

# Source: https://github.com/wotikama/nvidiafan/blob/main/nvidiafan.sh

# Function
setfan() {
  xhost +si:localuser:root
  sudo /run/current-system/sw/bin/nvidia-settings -a "*:1[gpu:0]/GPUFanControlState=1" -a "*:1[fan-0]/GPUTargetFanSpeed=$1" -a "*:1[fan-1]/GPUTargetFanSpeed=$1" -c $DISPLAY
  xhost -si:localuser:root
}

# Change 'setfan' parameter for speed % and 'X' intervals for temperature boundaries
for(( ; ; ))
do
X=$(/run/current-system/sw/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)
if ((0<=X && X<=40))
then
  setfan 40
elif ((41<=X && X<=70))
then
  setfan 55
elif ((71<=X && X<=78))
then
  setfan 70
elif ((79<=X && X<=85))
then
  setfan 85
elif ((86<=X && X<=100))
then
  setfan 100
fi

sleep 10
done
