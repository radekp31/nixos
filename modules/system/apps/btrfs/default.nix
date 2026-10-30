{pkgs, ...}: let
  # A scrub needs CAP_SYS_ADMIN and raw access to the block device, so the
  # capability set and the device nodes stay. Every knob below costs the scrub
  # nothing. The important one is PrivateNetwork: a scrub reads disks and has
  # no reason to hold a socket.
  #
  # Verify a change WITHOUT applying it:
  #   nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel
  #   systemd-analyze security --offline=true \
  #     ./result/etc/systemd/system/btrfs-scrub-nix.service
  scrubHardening = {
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    PrivateNetwork = true;
    PrivateTmp = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectProc = "invisible";
    ProcSubset = "pid";
    RestrictAddressFamilies = [""];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    UMask = "0077";
  };
in {
  # See fileSystems in hardware-config.nix

  services.btrfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/" "/nix"];
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

  # The unit name comes from the escaped mount point, so "/" becomes a single
  # dash and the unit is btrfs-scrub--, with two dashes. Keep these two names in
  # step with autoScrub.fileSystems above.
  systemd.services."btrfs-scrub--".serviceConfig = scrubHardening;
  systemd.services."btrfs-scrub-nix".serviceConfig = scrubHardening;

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
