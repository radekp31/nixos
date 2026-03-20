{
  config,
  pkgs,
  lib,
  ...
}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      cudaPackages.cudatoolkit
    ];
  };

  environment.systemPackages = with pkgs; [
    cudaPackages.cuda_nvcc
  ];

  #nixpkgs.config.allowUnfree = true;

  environment.sessionVariables = {
    # WSL NVIDIA driver, *and* CUDA libs (we'll use lib and lib64)
    LD_LIBRARY_PATH = lib.mkBefore "/usr/lib/wsl/lib:${pkgs.cudaPackages.cudatoolkit}/lib64:${pkgs.cudaPackages.cudatoolkit}/lib";

    # For the static linker (used by gcc/nvcc), prefer lib64 then lib
    LIBRARY_PATH = lib.mkBefore "${pkgs.cudaPackages.cudatoolkit}/lib64:${pkgs.cudaPackages.cudatoolkit}/lib";

    # CUDA headers (cuda_runtime.h, etc.)
    CPATH = lib.mkBefore "${pkgs.cudaPackages.cudatoolkit}/include";
  };

  # Prefer NixOS system binaries over WSL's
  environment.extraInit = ''
    export PATH=/run/current-system/sw/bin:"$PATH"
  '';
}
