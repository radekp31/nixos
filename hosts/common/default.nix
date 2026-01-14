{
  pkgs,
  lib,
  config,
  ...
}: {
  # Networking
  networking.networkmanager.enable = lib.mkDefault true;
  networking.firewall.enable = true;

  # Locale - use defaults that hosts can override
  time.timeZone = lib.mkDefault "Europe/Prague";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";

  # Security
  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;

  # Nix settings
  system.autoUpgrade = {
    enable = true;
    operation = "boot";
    flake = "git+https://github.com/radekp31/nixos.git#${config.networking.hostName}";
    dates = "02:30";
    randomizedDelaySec = "30min";
    persistent = true;
    allowReboot = false;
  };

  #Create notification after auto autoUpgrade
  systemd.services.nixos-upgrade = {
    # We use postStop because it runs after the main upgrade command finishes
    postStop = ''
      # Systemd provides $SERVICE_RESULT to this environment

      # 1. Determine the message based on the upgrade result
      if [ "$SERVICE_RESULT" = "success" ]; then
          TITLE="Upgrade Ready"
          MSG="System updated successfully. Please reboot to apply."
          ICON="nix-snowflake"
      else
          TITLE="Upgrade Failed"
          MSG="Auto-upgrade encountered an error. Check journalctl -u nixos-upgrade"
          ICON="dialog-error"
      fi

      # 2. Find all real users logged into a graphical session
      # This filters out the 'manager' and root to find your actual desktop session
      for SID in $(loginctl list-sessions --no-legend | awk '$6 != "manager" {print $1}'); do
          U_NAME=$(loginctl show-session "$SID" -p Name --value)
          U_ID=$(id -u "$U_NAME")

          # Only notify if the user has a bus available
          if [ -S "/run/user/$U_ID/bus" ]; then
            sudo -u "$U_NAME" \
              DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$U_ID/bus \
              busctl --user call \
                org.freedesktop.Notifications \
                /org/freedesktop/Notifications \
                org.freedesktop.Notifications \
                Notify \
                susssasa{sv}i \
                -- "NixOS Upgrade" 0 "$ICON" "$TITLE" "$MSG" 0 0 -1
          fi
      done
    '';
  };

  nix = {
    gc = {
      automatic = lib.mkDefault true; # Add mkDefault here too
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 7d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      keep-outputs = true;
      keep-derivations = true;
      min-free = 20 * 1024 * 1024 * 1024; # 20GB
      max-free = 50 * 1024 * 1024 * 1024; # 50GB
    };
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    # Core essentials
    vim
    wget
    curl
    git
    htop
    tree
    tmux
    nh
  ];

  # SSH - disabled by default, let hosts opt-in
  services.openssh = {
    enable = lib.mkDefault false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = lib.mkDefault false;
    };
  };

  programs.git = {
    enable = true;
  };
}
