_: {
  # The nix-ld shim owns /lib64/ld-linux-x86-64.so.2, a path outside the Nix
  # store, so only the system can create it.
  programs.nix-ld.enable = true;

  # This module sets no libraries. The heavy GUI library set lives in
  # flakes/compat.
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
  # Do not add nvidia_x11 here; it causes a driver version mismatch. Both
  # compat paths take the driver from the host at /run/opengl-driver.
}
