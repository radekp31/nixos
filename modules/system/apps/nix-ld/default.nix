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

    cudaPackages.cudatoolkit
    linuxPackages.nvidia_x11

    stdenv.cc.cc
    glib
    zlib
    libGL
    libGLU
    freeglut
    libXmu
    libXrandr
    libXv
    ncurses5
    binutils

    # Graphics / Electron / GUI requirements
    #xorg.libX11
    #xorg.libXcomposite
    #xorg.libXdamage
    #xorg.libXext
    #xorg.libXfixes
    #xorg.libXrandr
    #xorg.libXrender
    #xorg.libXtst
    #xorg.libXi
    #xorg.libXcursor
    #xorg.libXScrnSaver
    libx11
    libxcomposite
    libxdamage
    libXext
    libxfixes
    libxrandr
    libxrender
    libXtst
    libxi
    libxcursor
    libxscrnsaver
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
