{ config
, pkgs
, ...
}:

#let
#
#in

{
  #Accept NVIDIA licence
  nixpkgs.config.nvidia.acceptLicense = true;

  # Enable OpenGL
  hardware.graphics = {
    # formerly hardware.opengl, now hardware.graphics
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [

      amdvlk
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      libvdpau-va-gl
      nvidia-vaapi-driver
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      vulkan-validation-layers
      xorg.libXrandr
      libglvnd
      libdrm
    ];
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Ampere and newer (RTX 30xx) :(
    dynamicBoost.enable = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    #open = false;
    open = true;

    # Enable DRM kernel mode setting
    forceFullCompositionPipeline = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "565.77";
      sha256_64bit = "sha256-CnqnQsRrzzTXZpgkAtF7PbH9s7wbiTRNcM0SPByzFHw=";
      sha256_aarch64 = "sha256-CnqnQsRrzzTXZpgkAtF7PbH9s7wbiTRNcM0SPByzFHw=";
      openSha256 = "sha256-Fxo0t61KQDs71YA8u7arY+503wkAc1foaa51vi2Pl5I=";
      settingsSha256 = "sha256-VUetj3LlOSz/LB+DDfMCN34uA4bNTTpjDrb6C6Iwukk=";
      persistencedSha256 = "sha256-wnDjC099D8d9NJSp9D0CbsL+vfHXyJFYYgU3CwcqKww=";
    };
  };

  #Packages related to NVIDIA
  environment.systemPackages = with pkgs; [

    clinfo
    gwe
    nvtopPackages.nvidia
    virtualglLib
    vulkan-tools
    vulkan-loader
    lm_sensors

  ];

  # GPU runs hot due to lots of power fed to it
  powerManagement.powertop.enable = true;

  # Fan control on Wayland
  # maybe use system.activationScripts ?
  # powertop handles it well

  systemd.services.fancontrol = {
    enable = true;
    description = "Wayland fan control service";
    path = [ pkgs.sudo pkgs.xorg.xhost "/run/current-system/sw/bin/nvidia-smi" "/run/current-system/sw/bin/nvidia-settings" ];
    environment = {
      DISPLAY = ":0";
      WAYLAND_DISPLAY = "wayland-0";
      XAUTHORITY = "/run/user/1000/.Xauthority";
    };
    unitConfig = {
      Type = "simple";
      # ...
    };
    serviceConfig = {
      ExecStart = "/etc/nixos/modules/scripts/fan-control.sh";
      Environment = "XAUTHORITY=/run/user/1000/.Xauthority";
      # ...
    };
    wantedBy = [ "multi-user.target" ];
    # ...
  };
}
