{lib, ...}: {
  wsl.enable = true;
  wsl.defaultUser = lib.mkDefault "nixos";
  wsl.useWindowsDriver = true;

  # WSL networking - no DHCP
  networking.useDHCP = lib.mkDefault false;

  # hosts/common/default.nix sets the reverse path filter to STRICT. WSL runs
  # behind a Windows NAT, and this host runs podman with a bridge, so a return
  # packet can arrive on the wrong interface.
  # LOOSE keeps the check and drops no container traffic.
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv4.conf.default.rp_filter" = 2;
  };

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
