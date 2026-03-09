
  { config, pkgs, ... }: {

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
}
