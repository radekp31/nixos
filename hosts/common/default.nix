{
  pkgs,
  lib,
  config,
  ...
}: let
  hasNvme = lib.elem "nvme" config.boot.initrd.availableKernelModules;

  # One banner for the console (/etc/issue) and sshd (/etc/issue.net).
  legalBanner = ''
    WARNING: Authorized use only. This system is private property.
    All access is logged and monitored. Unauthorized access is prohibited
    and may be prosecuted. Disconnect now if you have no permission.
  '';
in {
  # Every my.* constant is declared here, so every host has every option.
  imports = [./options.nix];

  # Move tmpfs to RAM on nvme drives and compress it, uses dynamic allocation
  boot.tmp = lib.mkIf hasNvme {
    useTmpfs = true;
    tmpfsSize = "25%";
  };

  zramSwap = lib.mkIf hasNvme {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 15;
  };

  documentation = {
    enable = true;
    man = {
      enable = true;
      cache.enable = true;
    };
    dev.enable = true; # This is the crucial one for developer/section 2/3 man pages
  };

  services.udev.extraRules = lib.mkIf hasNvme ''
    # Set scheduler for NVMe to 'none' for maximum throughput
    ACTION=="add|change", KERNEL=="nvme[0-9]n[1-9]", ATTR{queue/scheduler}="none"
  '';

  # Networking
  #networking.networkmanager.enable = lib.mkDefault true;
  networking.resolvconf.enable = false;
  networking.firewall.enable = true;

  # Locale - use defaults that hosts can override
  time.timeZone = lib.mkDefault "Europe/Prague";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "us";

  # Security
  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;

  boot.kernel.sysctl = {
    # Deny the autoload of a TTY line discipline. This is a known local
    # privilege escalation path. No host here uses slip, ppp or can.
    "dev.tty.ldisc_autoload" = 0;

    # Refuse a write to a FIFO or a regular file in a world-writable sticky
    # directory when a different user owns that file. This stops the classic
    # /tmp race attack.
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;

    # Write no core dump for a setuid program. The kernel starts at 2, which
    # writes a root-only dump. The value 0 writes nothing.
    "fs.suid_dumpable" = 0;

    # Hide kernel pointers from every reader, root included.
    # TRADE-OFF, suboptimal for development: `perf` loses kernel symbol names
    # and some eBPF tools lose addresses. Set this key to 1 to get them back.
    "kernel.kptr_restrict" = 2;

    # Make the block on unprivileged BPF permanent for this boot. The kernel
    # starts at 2, and a privileged process can still reverse the value 2.
    "kernel.unprivileged_bpf_disabled" = 1;

    # Harden the BPF JIT against spray attacks.
    # TRADE-OFF: this costs a little BPF throughput. Nothing here needs it.
    "net.core.bpf_jit_harden" = 2;

    # Take no ICMP redirect and send none. No host here is a router.
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;

    # Log a packet that arrives with an impossible source address.
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    # Strict reverse path filter. The NixOS firewall runs a LOOSE check with
    # the rpfilter match and leaves this sysctl at 0, so the kernel never saw
    # a strict check. mkDefault, because a multi-homed host, a VPN or an
    # asymmetric route needs the value 2 instead.
    "net.ipv4.conf.all.rp_filter" = lib.mkDefault 1;
    "net.ipv4.conf.default.rp_filter" = lib.mkDefault 1;

    # Do not set kernel.modules_disabled = 1. It breaks NixOS. No module loads after boot, so `nixos-rebuild switch`,
    # the NVIDIA driver, KVM and USB hotplug all fail.
    #
    # Do not set kernel.sysrq here. hosts/nixos-desktop sets it to 1 for
    # kernel debugging, together with boot.shell_on_fail.
  };

  # Deny the autoload of four transport protocols. An unprivileged socket()
  # call loads each one through a module alias, and each one
  # carries a CVE history. Nothing in this repository uses them.
  boot.blacklistedKernelModules = ["dccp" "sctp" "rds" "tipc"];

  # NixOS builds /etc/issue from the getty lines.
  # This option takes type `lines`, so the text MERGES with the
  # "Run 'nixos-help'" line that the documentation module adds. Add no such
  # line here, or /etc/issue prints it twice.
  services.getty.helpLine = "\n" + legalBanner;

  environment.etc."issue.net".text = legalBanner;

  # Nix settings
  system.autoUpgrade = {
    enable = false; # A shell staleness check alerts instead; run upgrades manually.
    operation = "boot";
    flake = "git+${config.my.repo.url}#${config.networking.hostName}";
    persistent = true;
    allowReboot = false;
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
    lsof
    psmisc # killall, pstree, fuser
    bc
    vim
    wget
    curl
    git
    htop
    tree
    tmux

    #nix tools
    nh #nix helper
    nix-output-monitor #helper for rebuild debugging
    nix-prefetch-git
    nix-prefetch
    nix-prefetch-scripts
    nix-prefetch-docker
    nps # alternative to nix-search-cli

    #documentation
    man-pages # POSIX and Linux extra man-pages (sections 2, 3, 4, 5, 7)
    man-pages-posix # POSIX-specific variants
  ];

  # SSH - disabled by default, let hosts opt-in.
  #
  # Every setting below is explicit, so an upstream default change cannot
  # move it silently.
  services.openssh = {
    enable = lib.mkDefault false;

    settings = {
      # sshd prints this FILE before it authenticates the client.
      # Banner takes a path, not the text. services.openssh.banner is gone.
      Banner = "/etc/issue.net";

      PermitRootLogin = "no";
      PasswordAuthentication = lib.mkDefault false;
      KbdInteractiveAuthentication = lib.mkDefault false;

      # Bound a brute-force attempt. OpenSSH 10.5 also applies PerSourcePenalties
      # by default, so a repeated failure from one address earns a growing block.
      MaxAuthTries = 3;
      MaxSessions = 4;
      LoginGraceTime = 30;

      # Drop a session whose client stops answering after 10 minutes. A live
      # client answers the probe, so an idle session survives.
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;

      # Only a member of wheel may log in. Add a group here for a service account.
      AllowGroups = ["wheel"];

      # Deny the forwarding types that turn one SSH session into a pivot.
      # TCP forwarding stays ON: `ssh -L` and VS Code Remote SSH both need it.
      X11Forwarding = false;
      AllowAgentForwarding = false;
      PermitTunnel = "no";
      GatewayPorts = "no";
      PermitUserEnvironment = false;

      # Log the key fingerprint of every login.
      LogLevel = "VERBOSE";
    };
  };

  programs.git = {
    enable = true;
  };
}
