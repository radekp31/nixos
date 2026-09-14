{
  description = "On-demand compatibility environment for prebuilt Linux binaries.";

  # WHICH PATH DO I NEED?
  #
  # Use the default. It is the FHS sandbox. It gives a real /usr/lib,
  # /bin/bash, and /usr/share, so it fixes every case the light path fixes and
  # also fixes a binary that hardcodes an FHS path, reads a "#!/bin/bash"
  # shebang, or calls dlopen with an absolute path. It runs vendor installers
  # too. Your own PATH survives inside, because /nix and the host profiles stay
  # bound, so git, nvim, and your shell all still work.
  #
  #   nix develop /etc/nixos/flakes/compat                # interactive shell
  #   nix run /etc/nixos/flakes/compat                    # the same sandbox
  #   nix run /etc/nixos/flakes/compat -- ./installer.run # run one command
  #
  # Use `nix run` for one command. Do NOT use `nix develop -c CMD` on the
  # default shell: its shellHook execs the sandbox, so CMD never runs.
  #
  # Use the light path only for a reason. It sets two environment variables and
  # starts no sandbox, so it is faster. It also leaves /etc alone, which the
  # sandbox replaces with a tmpfs. Choose it when a binary reads an unusual
  # /etc file, or when the sandbox costs too much for a one-second job.
  #
  #   nix develop /etc/nixos/flakes/compat#light
  #
  # The two mechanisms never run together. nix-ld works by BEING the ELF
  # interpreter at /lib64/ld-linux-x86-64.so.2. Inside the sandbox that path is
  # the real glibc loader, so nix-ld is bypassed. NIX_LD and
  # NIX_LD_LIBRARY_PATH do leak into the sandbox, but nothing reads them there.
  #
  # THE GPU DRIVER
  #
  # Both paths take the NVIDIA driver from the host at /run/opengl-driver, so
  # the driver version always matches the running kernel module. Do not add
  # nvidia_x11 to the list below. That mistake caused a 595-against-610
  # mismatch before 2026-09-14.

  inputs = {
    # Track the same branch as the system flake. Keep the two in step.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # One list. Both entry points consume it.
        # Keep it sorted by purpose, so a future reader can delete a whole group.
        compatPkgs = p:
          with p; [
            # Base C runtime and compression
            stdenv.cc.cc.lib
            zlib
            openssl
            curl
            expat
            icu
            fuse3

            # Core services most desktop binaries open
            glib
            nss
            nspr
            dbus
            systemd
            alsa-lib
            cups
            libusb1

            # GTK and accessibility. Electron links these.
            gtk3
            cairo
            pango
            gdk-pixbuf
            atk
            at-spi2-atk
            at-spi2-core

            # Graphics. The vendor driver comes from the host, not from here.
            libGL
            mesa
            libdrm
            libgbm
            libxkbcommon

            # X11. XWayland applications need these.
            libx11
            libxcb
            libxcomposite
            libxcursor
            libxdamage
            libXext
            libxfixes
            libxi
            libxrandr
            libxrender
            libxscrnsaver
            libXtst
          ];

        # The FHS entry point. Run a command when arguments exist. Start an
        # interactive shell when they do not.
        fhsRunScript = pkgs.writeShellScript "compat-fhs-run" ''
          if [ "$#" -eq 0 ]; then
            exec bash
          fi
          exec "$@"
        '';

        fhs = pkgs.buildFHSEnv {
          name = "compat-fhs";
          targetPkgs = compatPkgs;
          # multiArch stays off. Electron is 64-bit only. Turn it on if a
          # 32-bit installer appears. It adds a full pkgsi686Linux tree.
          runScript = "${fhsRunScript}";

          # buildFHSEnv replaces /etc with a tmpfs, and chdirToPwd defaults to
          # true. This repository lives at /etc/nixos, so starting the sandbox
          # from the repository fails with "bwrap: Can't chdir to /etc/nixos".
          # Bind that one path back, read only. Each argument needs its own
          # list element, because the module joins them into a bash array.
          extraBwrapArgs = [
            "--ro-bind-try"
            "/etc/nixos"
            "/etc/nixos"
          ];
          profile = ''
            echo "compat FHS environment. /usr/lib is real here. Type exit to leave."
          '';
        };
      in {
        # The default path. It is the FHS sandbox, because it is a superset of
        # the light path and removes the need to choose.
        #
        # This execs the FHS wrapper explicitly. buildFHSEnv also ships an
        # `fhs.env` attribute for the legacy nix-shell, but the explicit exec
        # states the intent and is easy to test.
        devShells.default = pkgs.mkShell {
          shellHook = ''
            exec ${fhs}/bin/compat-fhs
          '';
        };

        # The light path. Reach for it only for the reasons in the header.
        devShells.light = pkgs.mkShell {
          # Take the loader from THIS nixpkgs, not from the system. The loader
          # and the libraries then come from one nixpkgs, so a glibc version
          # can never disagree with a library.
          NIX_LD = pkgs.stdenv.cc.bintools.dynamicLinker;
          NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (compatPkgs pkgs);

          shellHook = ''
            echo "compat nix-ld shell. NIX_LD and NIX_LD_LIBRARY_PATH are set."
            echo "No sandbox here. If a binary still fails, use the default:"
            echo "  nix develop /etc/nixos/flakes/compat"
          '';
        };

        packages.fhs = fhs;
        packages.default = fhs;

        apps.fhs = {
          type = "app";
          program = "${fhs}/bin/compat-fhs";
        };

        # `nix run` with no attribute gives the sandbox too, and it accepts a
        # command after `--`. This is the supported way to run one command.
        apps.default = {
          type = "app";
          program = "${fhs}/bin/compat-fhs";
        };
      }
    );
}
