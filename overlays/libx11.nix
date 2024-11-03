# libx11-overlay.nix
{ pkgs }: {
  libX11 = pkgs.libX11.overrideAttrs (oldAttrs: {
    version = "1.8.1";
    src = pkgs.fetchurl {
      url = "https://www.x.org/archive/individual/lib/libX11-1.8.1.tar.gz";
      sha256 = "0r9yp2zjz2wvjqiwvr89fp7vfv4nwj26afcc3cmq5vcdzg3xkbha"; # Replace this with the correct sha256
    };
  });
}
