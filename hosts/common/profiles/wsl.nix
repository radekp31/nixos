{lib, ...}: {
  wsl.enable = true;
  wsl.defaultUser = lib.mkDefault "nixos";
  wsl.useWindowsDriver = true;

  # WSL networking - no DHCP
  networking.useDHCP = lib.mkDefault false;

  # Environment variables for WSL
  environment.variables = {
    EDITOR = lib.mkDefault "vim";
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  users.users.root.subUidRanges = [
    {
      startUid = 100000;
      count = 655360;
    }
  ];
  users.users.root.subGidRanges = [
    {
      startGid = 100000;
      count = 655360;
    }
  ];
}
