{pkgs, ...}: {
  services.cockpit.enable = true;

  # Additional extensions: https://cockpit-project.org/applications.html
  # Make derivations for:
  # Storage
  # Network
  # Podman
  # Kernel Dump
  # Diagnostics
  # Cockpit files | Navigator
  # ZFS Manager
  # File Sharing
  # Benchmark
  # Sensors
  # Tailscale
  # Cloudflare tunnels
  # Backblaze

  environment.systemPackages = with pkgs; [
    cockpit
  ];
}
