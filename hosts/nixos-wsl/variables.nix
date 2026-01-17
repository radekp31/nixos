{lib, ...}: {
  options.catppuccinTheme = lib.mkOption {
    type = lib.types.enum ["latte" "frappe" "macchiato" "mocha"]; # 'latte', 'frappe' and ',mocha' dont work in foot
    default = "macchiato";
    description = "The Catppuccin flavor for this specific host.";
  };

  config.catppuccinTheme = "macchiato";
}
