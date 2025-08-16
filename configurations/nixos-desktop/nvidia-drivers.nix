{
  config,
  pkgs,
  ...
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
      #xorg.libXrandr
      libglvnd
      libdrm
    ];
  };

  # Force modeset=1
  boot.kernelParams = ["nvidia_drm.fbdev=1"];
  boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

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
    open = false;
    #open = true;

    # Enable DRM kernel mode setting
    forceFullCompositionPipeline = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    #  version = "570.86.16";
    #  sha256_64bit = "sha256-RWPqS7ZUJH9JEAWlfHLGdqrNlavhaR1xMyzs8lJhy9U=";
    #  sha256_aarch64 = "sha256-RiO2njJ+z0DYBo/1DKa9GmAjFgZFfQ1/1Ga+vXG87vA=";
    #  openSha256 = "sha256-DuVNA63+pJ8IB7Tw2gM4HbwlOh1bcDg2AN2mbEU9VPE=";
    #  settingsSha256 = "sha256-9rtqh64TyhDF5fFAYiWl3oDHzKJqyOW3abpcf2iNRT8=";
    #  persistencedSha256 = "sha256-3mp9X/oV8o2TH9720NnoXROxQ4g98nNee+DucXpQy3w=";
    #};

    #package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    #  version = "575.51.02";
    #  sha256_64bit = "sha256-XZ0N8ISmoAC8p28DrGHk/YN1rJsInJ2dZNL8O+Tuaa0=";
    #  sha256_aarch64 = "sha256-NNeQU9sPfH1sq3d5RUq1MWT6+7mTo1SpVfzabYSVMVI=";
    #  openSha256 = "sha256-NQg+QDm9Gt+5bapbUO96UFsPnz1hG1dtEwT/g/vKHkw=";
    #  settingsSha256 = "sha256-6n9mVkEL39wJj5FB1HBml7TTJhNAhS/j5hqpNGFQE4w=";
    #  persistencedSha256 = "sha256-dgmco+clEIY8bedxHC4wp+fH5JavTzyI1BI8BxoeJJI=";
    #};
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

  #systemd.services.fancontrol = {
  #  enable = true;
  #  description = "Wayland fan control service";
  #  path = [ pkgs.sudo pkgs.xorg.xhost "/run/current-system/sw/bin/nvidia-smi" "/run/current-system/sw/bin/nvidia-settings" ];
  #  environment = {
  #    DISPLAY = ":0";
  #    WAYLAND_DISPLAY = "wayland-0";
  #    XAUTHORITY = "/run/user/1000/.Xauthority";
  #  };
  #  unitConfig = {
  #    Type = "simple";
  #    # ...
  #  };
  #  serviceConfig = {
  #    ExecStart = "/etc/nixos/modules/scripts/fan-control.sh";
  #    Environment = "XAUTHORITY=/run/user/1000/.Xauthority";
  #    # ...
  #  };
  #  wantedBy = [ "multi-user.target" ];
  #  # ...
  #};
}
