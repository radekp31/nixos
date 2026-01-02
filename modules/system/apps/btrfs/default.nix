{pkgs, ...}: {
  # See fileSystems in hardware-config.nix

  services.btrfs = {
    autoScrub = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [btrbk];

  systemd.tmpfiles.rules = [
    "d /mnt/btr_pool/.snapshots 0700 root root -"
    "d /mnt/btr_pool/.snapshots/@ 0700 root root -"
    "d /mnt/btr_pool/.snapshots/@home 0700 root root -"
  ];

  services.btrbk.instances."local" = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "2d";
      snapshot_preserve = "24h 14d 12w";

      volume."/mnt/btr_pool" = {
        # This creates snapshots in /mnt/btr_pool/.snapshots/
        # Serves as "management group", subvolumes can be mounted multiple times
        snapshot_dir = ".snapshots";

        subvolume."@home" = {}; # Inherits hourly

        subvolume."@" = {
          # Set to manual/ondemand
          snapshot_create = "ondemand";
        };
      };
    };
  };

  systemd.services.btrbk-daily-root = {
    description = "Trigger daily btrbk snapshots for root";

    # Ensure the btrbk service is available
    after = ["local-fs.target"];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.btrbk}/bin/btrbk -c /etc/btrbk/local.conf run @";
      User = "root";
    };
  };

  systemd.timers.btrbk-daily-root = {
    description = "Timer for daily root snapshots";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true; # Run immediately if the computer was off at midnight
    };
  };
}
