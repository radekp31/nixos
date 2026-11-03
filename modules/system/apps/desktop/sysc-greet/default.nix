# sysc-greet: a greetd greeter. greetd starts sway, and sway runs sysc-greet
# in kitty. Kitty draws text with the system fonts.
#
# This module replaces the upstream NixOS module. The upstream package keeps
# a greeter config for each of five compositors, with full store paths, so
# the system also got niri and Hyprland (123 MiB). This package installs only
# the sway config.
{
  config,
  pkgs,
  inputs,
  ...
}: let
  # Keep the version the same as the tag of the sysc-greet input in flake.nix.
  sysc-greet = pkgs.buildGo126Module rec {
    pname = "sysc-greet";
    version = "1.3.2";
    src = inputs.sysc-greet;
    # From the upstream flake.nix. When go.mod changes, the build fails and
    # prints the new hash.
    vendorHash = "sha256-6JhzDC7uu9RC4K9WJTzOR2DMo+nsUStrVQWl9KdecQw=";
    subPackages = ["cmd/sysc-greet"];
    ldflags = [
      "-X main.Version=${version}"
      "-X main.GitCommit=${inputs.sysc-greet.rev}"
      "-X main.BuildDate=1970-01-01"
      "-X main.dataDir=${placeholder "out"}/share/sysc-greet"
    ];
    # The Assets folder (18 MiB) is left out: no code reads it.
    postInstall = ''
      data=$out/share/sysc-greet
      mkdir -p $data/themes
      cp -r ascii_configs fonts wallpapers THIRD_PARTY_NOTICES.md $data/
      cp -r cmd/sysc-greet/assets/borders $data/
      cp themes/*.toml $data/themes/

      install -Dm644 config/kitty-greeter.conf $out/etc/greetd/kitty.conf
      install -Dm644 config/sway-greeter-config $out/etc/greetd/sway-greeter-config
      substituteInPlace $out/etc/greetd/sway-greeter-config \
        --replace-fail /usr/local/bin/sysc-greet $out/bin/sysc-greet \
        --replace-fail "kitty " "${pkgs.kitty}/bin/kitty " \
        --replace-fail "swaymsg " "${pkgs.sway}/bin/swaymsg "
    '';
    meta.mainProgram = "sysc-greet";
  };
in {
  services.greetd = {
    enable = true;
    # A full path keeps sway out of systemPackages. Otherwise sway.desktop
    # shows in the session list. On the proprietary NVIDIA driver, sway 1.12
    # shows a swaynag warning bar without --unsupported-gpu.
    # greetd connects the session output to tty1. systemd-cat sends it to
    # the journal, so the console shows no log text when sway exits.
    settings.default_session.command = "${config.systemd.package}/bin/systemd-cat -t sysc-greet ${pkgs.sway}/bin/sway --unsupported-gpu -c ${sysc-greet}/etc/greetd/sway-greeter-config";
  };

  # sysc-greet starts the session with an empty environment. pam_systemd
  # reads XDG_SESSION_TYPE from the greetd unit, so logind registers the
  # greeter and the desktop session as wayland, not tty.
  systemd.services.greetd.environment.XDG_SESSION_TYPE = "wayland";

  # The sway config sets HOME to this folder. sysc-greet keeps its
  # preferences in it and looks for wallpapers in it.
  users.users.greeter = {
    home = "/var/lib/greeter";
    createHome = true;
  };

  # The sway config and the screensaver on a second monitor read this path.
  environment.etc."greetd/kitty.conf".source = "${sysc-greet}/etc/greetd/kitty.conf";

  # sysc-greet reads sessions only from /run/current-system/sw/share/wayland-sessions.
  environment.pathsToLink = ["/share/wayland-sessions"];

  environment.systemPackages = [
    # sysc-greet finds these two on PATH: kitty for the screensaver on a
    # second monitor, gslapper for the wallpaper.
    pkgs.kitty
    inputs.sysc-greet.inputs.gslapper.packages.${pkgs.stdenv.hostPlatform.system}.default

    # GNOME session for sysc-greet. GNOME is the only desktop on this host.
    # GNOME's own session file is in gnome-session.sessions, and NixOS does
    # not link it into the path above. sysc-greet also does not send the
    # desktop variables that tuigreet and GDM send. systemd-cat sends the
    # gnome-session output to the journal, not tty1.
    (pkgs.writeTextDir "share/wayland-sessions/gnome.desktop" ''
      [Desktop Entry]
      Name=GNOME
      Exec=${config.systemd.package}/bin/systemd-cat -t gnome-session ${pkgs.coreutils}/bin/env XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_DESKTOP=gnome DESKTOP_SESSION=gnome ${pkgs.gnome-session}/bin/gnome-session
      Type=Application
      DesktopNames=GNOME
    '')
  ];

  # The greeter can power off and reboot when other sessions are open.
  # The rule is from the upstream module.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
           action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.reboot-multiple-sessions") &&
          subject.user == "greeter") {
        return polkit.Result.YES;
      }
    });
  '';
}
