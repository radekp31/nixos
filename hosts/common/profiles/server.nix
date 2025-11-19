{
  pkgs,
  lib,
  ...
}: {
  # SSH - secure defaults
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkDefault "prohibit-password";
    };
  };

  # Firewall - strict by default
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22]; # SSH only
    allowedUDPPorts = [53 123]; # DNS and NTP
  };

  # More conservative GC for servers
  nix.gc = {
    dates = lib.mkForce "weekly";
    options = lib.mkForce "--delete-older-than 30d";
  };

  # Bash configuration for servers
  programs.bash = {
    shellInit = ''
      bind "set show-all-if-ambiguous on"
      bind "TAB:menu-complete"
    '';
  };

  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };

  # Minimal server packages
  environment.systemPackages = with pkgs; [
    # Already in common/default.nix: vim, wget, curl, git, htop, tree
  ];
}
