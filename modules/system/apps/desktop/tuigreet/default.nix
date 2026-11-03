# tuigreet: a text greeter for greetd. It draws on the kernel console, so
# it can show only the glyphs of the console font. The GNOME module sets the
# console font to ter-v22b.
{
  config,
  pkgs,
  ...
}: let
  # The matrix rain uses half-width katakana, and no console font has
  # katakana, so they show as boxes. The patch uses Cyrillic and Greek
  # letters that ter-v22b has.
  tuigreet = pkgs.tuigreet.overrideAttrs (old: {
    patches = (old.patches or []) ++ [../../../../../patches/tuigreet-matrix-console-glyphs.patch];
  });
in {
  services.greetd = {
    enable = true;
    # Keeps boot and kernel messages from drawing over tuigreet.
    useTextGreeter = true;
    #settings.default_session.command = builtins.concatStringsSep " " [
    #  "${tuigreet}/bin/tuigreet"
    #  "--time"
    #  "--remember"
    #  "--remember-session"
    #  "--greeting 'radekp'"
    #  "--theme 'border=blue;text=cyan;prompt=green;time=blue'"
    #  "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
    #  "--session-wrapper '${config.systemd.package}/bin/systemd-cat -t gnome-session'"
    #];
    settings.default_session.command = builtins.concatStringsSep " " [
      "${tuigreet}/bin/tuigreet"
      "--remember"
      "--remember-session"
      "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
      # greetd connects the session output to tty1. systemd-cat sends it to
      # the journal.
      "--session-wrapper '${config.systemd.package}/bin/systemd-cat -t gnome-session'"
    ];
  };

  environment.etc."tuigreet/config.toml".text = ''
    [display]
    show_time = true
    greeting = "radekp"
    align_greeting = "center"

    [background]
    kind = "matrix"
    fps = 30

    [background.matrix]
    head_color = "#e8fbff"
    bright_color = "#2b6cb0"
    dim_color = "#0d3a5c"
    min_length = 6
    max_length = 18
    min_speed = 0.30
    max_speed = 1.10
    mutate_chance = 0.02

    [theme]
    border = "blue"
    text = "cyan"
    prompt = "green"
    time = "blue"
  '';
}
