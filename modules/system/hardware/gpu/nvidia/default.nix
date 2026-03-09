{
  config,
  pkgs,
  lib,
  ...
}: let
  isWSL = config.networking.hostName == "dt-wsl-nix";
in {
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
    kernelParams = [
      "nvidia_drm.fbdev=1"
      "modprobe.blacklist=nouveau"
      "nouveau.modeset=0"
    ];
    supportedFilesystems = [
      "ntfs"
      "vfat"
      "ext4"
    ];
    initrd = {
      # nixosConfigurations.dt-wsl-nix.config.networking.hostName
      enable = lib.mkForce (
        if isWSL
        then false
        else true
      );
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

  #systemd.services.nvidia-powerd.enable = false;
  systemd.services.nvidia-powerd.enable = lib.mkForce (
    if isWSL
    then false
    else true
  );

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
    #package = config.boot.kernelPackages.nvidiaPackages.beta;

    # Pin specific driver version
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "595.45.04";
      sha256_64bit = "sha256-zUllSSRsuio7dSkcbBTuxF+dN12d6jEPE0WgGvVOj14=";
      sha256_aarch64 = "sha256-jl6lQWsgF6ya22sAhYPpERJ9r+wjnWzbGnINDpUMzsk=";
      openSha256 = "sha256-uqNfImwTKhK8gncUdP1TPp0D6Gog4MSeIJMZQiJWDoE=";
      settingsSha256 = "sha256-Y45pryyM+6ZTJyRaRF3LMKaiIWxB5gF5gGEEcQVr9nA=";
      persistencedSha256 = "sha256-5FoeUaRRMBIPEWGy4Uo0Aho39KXmjzQsuAD9m/XkNpA=";
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

  programs.coolercontrol.enable = true;

  #Create power limit service
  systemd.services.nv-power-limit = {
    #enable = true;
    enable = lib.mkForce (
      if isWSL
      then false
      else true
    );
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
