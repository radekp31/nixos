#!/bin/sh

trap "exit" SIGTERM

/run/current-system/sw/bin/nvidia-settings -a '[gpu:0]/GPUFanControlState=1'

while true; do

GPUTEMP=$(/run/current-system/sw/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader)

    if [[ $GPUTEMP -gt 15 ]]; then
        /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=30' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=30';
    fi

    if [[ $GPUTEMP -gt 40 ]]; then
        /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=45' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=45';
    fi

    if [[ $GPUTEMP -gt 50 ]]; then
        /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=65' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=65';
    fi

    if [[ $GPUTEMP -gt 60 ]]; then
        /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=75' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=75';
    fi

    if [[ $GPUTEMP -gt 65 ]]; then
        /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=90' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=90';
    fi

    if [[ $GPUTEMP -gt 81 ]]; then
        /run/current-system/sw/bin/nvidia-settings -a '[fan:0]/GPUTargetFanSpeed=100' && /run/current-system/sw/bin/nvidia-settings -a '[fan:1]/GPUTargetFanSpeed=100';
    fi

    sleep 2
done
