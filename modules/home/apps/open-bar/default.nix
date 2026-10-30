{lib, ...}: let
  # Catppuccin Macchiato, as RGB floats in strings (the Open Bar format).
  # These are the vicinae theme colors.
  base = ["0.141" "0.153" "0.227"]; # #24273A background
  mantle = ["0.118" "0.125" "0.188"]; # #1E2030 secondary background
  border = ["0.275" "0.298" "0.443"]; # #464C71 border
  selection = ["0.275" "0.290" "0.416"]; # #464A6A list selection
  text = ["0.792" "0.827" "0.961"]; # #CAD3F5 foreground
  blue = ["0.541" "0.678" "0.957"]; # #8AADF4 accent
  black = ["0.0" "0.0" "0.0"];

  # Open Bar keeps a dark-mode copy of each color and copies it back when the
  # color scheme changes. Set both, or the old colors return.
  colors = {
    accent-color = blue;
    bgcolor = base;
    fgcolor = text;
    bcolor = border;
    hcolor = selection;
    iscolor = base;
    boxcolor = base;
    mbgcolor = base;
    mfgcolor = text;
    mbcolor = border;
    mhcolor = selection;
    mscolor = blue;
    mshcolor = black;
    smbgcolor = mantle;
  };
in {
  # Open Bar (GNOME extension) styled like the vicinae launcher. The package
  # is in modules/system/apps/desktop/gnome. Nix owns only these keys: a change
  # to one of them in the Open Bar settings window is lost at the next switch.
  dconf.settings."org/gnome/shell/extensions/openbar" =
    colors
    // lib.mapAttrs' (name: lib.nameValuePair "dark-${name}") colors
    // {
      # No wallpaper auto theme: it would replace these colors.
      autotheme-refresh = false;
      autofg-bar = false;
      autofg-menu = false;
      autohg-bar = false;
      autohg-menu = false;
      accent-override = true;

      # Bar: one floating card, like the vicinae window.
      bartype = "Floating";
      height = 34.0;
      margin = 6.0;
      bgalpha = 0.95;
      fgalpha = 1.0;
      balpha = 1.0;
      bwidth = 1.0;
      bradius = 12.0;
      neon = false;
      gradient = false;
      shadow = false;
      halpha = 1.0;
      isalpha = 0.0;
      boxalpha = 0.0;
      # Keep one bar color. On: a maximized window gives the bar another color.
      wmaxbar = false;

      # Menus (calendar, quick settings): the same card style.
      menustyle = true;
      mbgalpha = 0.97;
      mfgalpha = 1.0;
      mbalpha = 1.0;
      mhalpha = 1.0;
      msalpha = 1.0;
      mshalpha = 0.25;
      smbgoverride = true;
      smbgalpha = 0.97;
      menu-radius = 12.0;
      notif-radius = 10.0;
      qtoggle-radius = 12.0;
    };
}
