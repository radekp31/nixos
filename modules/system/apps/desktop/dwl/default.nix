{ config, pkgs, lib, ... }:

let
  # Reverse override order: patch first, inject configH last
patchedDwl = (pkgs.dwl.override {
    configH = ./config.h;
  }).overrideAttrs (oldAttrs: {
    patchFlags = [ "-p1" "-F3" ];

    patches = (oldAttrs.patches or [ ]) ++ [
      ./patches/hot-reload-0.8.patch
      ./patches/bar-0.7.patch
    ];

    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
      pkgs.fcft
      pkgs.libdrm
    ];

    env = (oldAttrs.env or { }) // {
      NIX_CFLAGS_COMPILE = "-Wno-error -Wno-missing-field-initializers -Wno-unused-macros -Wno-pedantic";
    };
  });

slStatus = pkgs.stdenv.mkDerivation {
    pname = "slstatus";
    version = "0.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "tonybanters";
      repo = "slstatus";
      rev = "d4dc0e2ee5f8a7c5ff72667417776c4a39dac16d";
      hash = "sha256-SNVh+FBkdVF+nUsSamYbegIoY/d5ss65BZ6+jdgnxN4=";

    };

    nativeBuildInputs = with pkgs; [ gnumake gcc pkg-config ];
    
    # Core X11/System libraries needed by slstatus to populate config.mk macros cleanly
    buildInputs = with pkgs; [ 
      xorg.libX11 
      xorg.libXau 
      xorg.libXdmcp 
      alsa-lib 
      libsndfile 
      sndio 
    ];

    # Create config.h and disable hardening flags that trigger warnings on old C macro generation
    preConfigure = ''
      cp -f config.def.h config.h
      export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -Wno-error"
    '';

    # Tell Make where to install and which C compiler wrapper to use
    makeFlags = [
      "PREFIX=$(out)"
      "CC=${pkgs.stdenv.cc.targetPrefix}cc"
    ];

    # Run direct install target to prevent running 'make clean' in read-only store
    installTargets = [ "install" ];

    meta = with pkgs.lib; {
      description = "slstatus for dwl";
      homepage = "https://github.com/tonybanters/slstatus";
      license = licenses.isc;
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  programs.dwl = {
    enable = true;
    package = patchedDwl;

    extraSessionCommands = ''
      systemctl --user import-environment \
        DISPLAY \
        WAYLAND_DISPLAY \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_TYPE \
	COLORSCHEME = prefer-dark \
        GTK_THEME = Adwaita:dark \
        QT_QPA_PLATFORMTHEME = gtk2
    '';
  };

  environment.systemPackages = with pkgs; [
    fuzzel
    wmenu
    yambar
    xdg-terminal-exec
    slStatus
  ];

  environment.etc."yambar/config.yml".text = ''
    bar:
      location: top
      height: 24
      background: 222222ff
      foreground: d0d0d0ff
      font: monospace:size=10
      right:
        - clock:
            content:
              - string:
                  text: "{time}"
  '';

  systemd.user.services.yambar = {
    description = "Yambar status bar";
    wantedBy = [ "dwl-session.target" ];
    partOf = [ "dwl-session.target" ];
    after = [ "dwl-session.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.yambar}/bin/yambar";
      Restart = "on-failure";
      RestartSec = "1s";
    };
  };
}
