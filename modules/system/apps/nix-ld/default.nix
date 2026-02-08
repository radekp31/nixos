{pkgs, ...}: {
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # General-purpose libraries for most binaries
    stdenv.cc.cc
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
    nspr

    # Graphics / Electron / GUI requirements
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXi
    xorg.libXcursor
    xorg.libXScrnSaver
    libxcb
    libxkbcommon
    mesa
    libdrm
    libgbm
    gtk3
    pango
    cairo
    gdk-pixbuf
    glib
    libglibutil
    libusb1
    atk
    at-spi2-atk
    at-spi2-core
    dbus
    cups
    libglibutil
    alsa-lib
    systemd
  ];
}
