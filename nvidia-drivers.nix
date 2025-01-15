{
  config,
  lib,
  pkgs,
  fetchpatch,
  ...
}:

let

  # Fixes drm device not working with linux 6.12
  # https://github.com/NVIDIA/open-gpu-kernel-modules/issues/712
  drm_fop_flags_linux_612_patch = pkgs.fetchpatch {
    url = "https://github.com/Binary-Eater/open-gpu-kernel-modules/commit/8ac26d3c66ea88b0f80504bdd1e907658b41609d.patch";
    hash = "sha256-+SfIu3uYNQCf/KXhv4PWvruTVKQSh4bgU1moePhe57U=";
  };

in

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
      #vulkan-loader
      #vulkan-tools
    ];
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  #NVIDIA env vars
  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  #Load kernel Modules
  boot.kernelModules = [
    "nvidia_uvm"
    "nvidia_modeset"
    "nvidia_drm"
    "nvidia"
  ];

  #Set kernel params
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "ibt=off"
  ]; # Required by Hyprland

  #boot.kernelParams = ["nvidia-drm.fbdev=1"];

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

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "565.57.01";
      sha256_64bit = "sha256-buvpTlheOF6IBPWnQVLfQUiHv4GcwhvZW3Ks0PsYLHo=";
      sha256_aarch64 = "sha256-aDVc3sNTG4O3y+vKW87mw+i9AqXCY29GVqEIUlsvYfE=";
      openSha256 = "sha256-/tM3n9huz1MTE6KKtTCBglBMBGGL/GOHi5ZSUag4zXA=";
      settingsSha256 = "sha256-H7uEe34LdmUFcMcS6bz7sbpYhg9zPCb/5AmZZFTx1QA=";
      persistencedSha256 = "sha256-hdszsACWNqkCh8G4VBNitDT85gk9gJe1BlQ8LdrYIkg=";
      patchesOpen = [ drm_fop_flags_linux_612_patch ];
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
    #powertop
    lm_sensors
    
  ];

  # GPU runs hot due to lots of power fed to it
  powerManagement.powertop.enable = true;

  programs.tuxclocker = {
    enable = true;
  };
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
