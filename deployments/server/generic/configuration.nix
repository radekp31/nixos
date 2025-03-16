# flakes need to be enabled
# shell need to be forced by mkForce to bash
# port 22 needs to be opened
# After deployment - AGE key will be generated. It has to be added to .sops.yaml. Without it, the server wont be able to decrypt the secrets/secrets.yaml

{ modulesPath
, lib
, pkgs
, ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Set nix flakes, and $NIX_PATH (hopefully this also fixed nix channels - update: It doesnt)
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };


  # Configure Nixpkgs to use the unstable channel for system-wide packages
  nixpkgs.config = {
    allowUnfree = true;
    channels = {
      enable = true;
      urls = [ "https://nixos.org/channels/nixpkgs-unstable" ];
    };
  };

  #services.openssh.enable = true;
  services.openssh = {
    enable = true;
    # Optional: Configure SSH settings
    settings = {
      PasswordAuthentication = false; # Set to false to disable password login
    };
  };

  # Open port 22 in the firewall
  networking.firewall = {
    enable = true; # Enable the firewall
    allowedTCPPorts = [ 22 ]; # Allow SSH connections
    # Optional: if you're using IPv6
    # allowedTCPPorts = [ 22 ];       # Same for IPv6
    rejectPackets = false; #Drop packets instead of REJECT
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  #users.users.radekp = {
  #  isNormalUser = true;
  #  extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #  initialHashedPassword = "$y$j9T$qsPcS6PZU.ikacpJSivZw.$PcGv5mJTBRGSIQ1lzFUpzvPIb2cDpX3EDqWuvQQjOE2";
  #  packages = with pkgs; [
  #    tree
  #    git
  #    curl
  #    vim
  #  ];
  #};

  #users.users.root.initialHashedPassword = "$y$j9T$qsPcS6PZU.ikacpJSivZw.$PcGv5mJTBRGSIQ1lzFUpzvPIb2cDpX3EDqWuvQQjOE2";
  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzoVRVWpxFy1dOe0vVrtv2c/i9GixoyUDKpgsuruSG2 radekp@nixos-desktop"
  ];

  #Force root shell to bash
  users.users.root.shell = lib.mkForce pkgs.bash;

  system.stateVersion = "24.05";
}
