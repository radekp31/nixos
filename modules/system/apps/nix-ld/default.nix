_: {
  # The nix-ld shim costs 67.8 KiB. It owns /lib64/ld-linux-x86-64.so.2, a path
  # outside the Nix store, so only the system can create it. The shim stays.
  programs.nix-ld.enable = true;

  # This module sets no libraries on purpose.
  #
  # The heavy GUI library set moved to flakes/compat on 2026-09-14. It cost
  # 6.0 GiB in every system closure, and the machine needs it only occasionally.
  #
  # programs.nix-ld.libraries is a list option, so any value here MERGES with
  # the upstream default in nixos/modules/programs/nix-ld.nix. That default
  # already covers zlib, zstd, stdenv.cc.cc, curl, openssl, libxml2, xz, and
  # systemd. Those serve most pip wheels and node native modules for free.
  # An explicit list here can only add weight. Use lib.mkForce [] to go lower,
  # which is not worth the lost base.
  #
  # When a binary fails with "cannot find libfoo.so", run the default. It is
  # the FHS sandbox, and it is a superset of the nix-ld path:
  #   nix develop /etc/nixos/flakes/compat           # interactive shell
  #   nix run /etc/nixos/flakes/compat -- ./binary   # one command
  # For a faster path that starts no sandbox:
  #   nix develop /etc/nixos/flakes/compat#light
  #
  # Do not add nvidia_x11 here. The old list pinned 595.71.05 against a
  # 610.57.04 kernel module and broke graphics at random. Both compat paths
  # take the driver from the host at /run/opengl-driver instead.
}
