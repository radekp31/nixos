{lib, ...}: {
  wsl.enable = true;
  wsl.defaultUser = lib.mkDefault "nixos";

  # WSL networking - no DHCP
  networking.useDHCP = lib.mkDefault false;

  # Environment variables for WSL
  environment.variables = {
    EDITOR = lib.mkDefault "vim";
    NIXPKGS_ALLOW_UNFREE = "1";
  };
}
