{
  config,
  pkgs,
  ...
}: {
  #Accept NVIDIA licence
  nixpkgs.config.nvidia.acceptLicense = true;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      libvdpau-va-gl
      nvidia-vaapi-driver
      intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      libva-vdpau-driver
      vulkan-validation-layers
      libglvnd
      libdrm
      dxvk
      mesa
    ];
  };

  boot = {
    kernelParams = ["nvidia_drm.fbdev=1"];
    supportedFilesystems = [
      "ntfs"
      "vfat"
      "ext4"
    ];
    initrd = {
      enable = true;
      supportedFilesystems = [
        "ntfs"
        "vfat"
        "ext4"
      ];
      availableKernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
    };
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  systemd.services.nvidia-powerd.enable = false;

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Persistence mode
    # Required for power limit to stay
    nvidiaPersistenced = true;

    # Ampere and newer (RTX 30xx) :(
    dynamicBoost.enable = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = true;

    # Enable DRM kernel mode setting
    forceFullCompositionPipeline = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    #package = config.boot.kernelPackages.nvidiaPackages.latest;
    #package = config.boot.kernelPackages.nvidiaPackages.production;

    # Pin specific driver version
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "590.48.01";
      sha256_64bit = "sha256-ueL4BpN4FDHMh/TNKRCeEz3Oy1ClDWto1LO/LWlr1ok=";
      sha256_aarch64 = "sha256-FOz7f6pW1NGM2f74kbP6LbNijxKj5ZtZ08bm0aC+/YA=";
      openSha256 = "sha256-hECHfguzwduEfPo5pCDjWE/MjtRDhINVr4b1awFdP44=";
      settingsSha256 = "sha256-NWsqUciPa4f1ZX6f0By3yScz3pqKJV1ei9GvOF8qIEE=";
      persistencedSha256 = "sha256-wsNeuw7IaY6Qc/i/AzT/4N82lPjkwfrhxidKWUtcwW8=";
    };
  };

  #Packages related to NVIDIA
  environment.systemPackages = with pkgs; [
    clinfo
    nvtopPackages.nvidia
    virtualglLib
    vulkan-tools
    vulkan-loader
    lm_sensors
  ];

  #Create power limit service
  systemd.services.nv-power-limit = {
    enable = true;
    path = with pkgs; [
      "${config.hardware.nvidia.package.bin}/bin/nvidia-smi"
      bash
    ];
    wantedBy = ["multi-user.target"];
    description = "Nvidia-smi power limit setting";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${config.hardware.nvidia.package.bin}/bin/nvidia-smi -i 0 -pl 130
    '';
  };

  # Conditionally create niri profile
  #environment.etc = lib.mkIf niriEnabled {
  #  "nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text = builtins.toJSON {
  #    rules = [
  #      {
  #        pattern = {
  #          feature = "procname";
  #          matches = "niri";
  #        };
  #        profile = "Limit Free Buffer Pool On Wayland Compositors";
  #      }
  #    ];
  #    profiles = [
  #      {
  #        name = "Limit Free Buffer Pool On Wayland Compositors";
  #        settings = [
  #          {
  #            key = "GLVidHeapReuseRatio";
  #            value = 0;
  #          }
  #        ];
  #      }
  #    ];
  #  };
  #};
}
