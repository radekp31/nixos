{
  inputs,
  osConfig,
  ...
}: {
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  catppuccin = {
    enable = true;
    flavor =
      if (osConfig ? catppuccinTheme)
      then osConfig.catppuccinTheme
      else "macchiato";

    foot = {
      enable = true;
    };
  };
}
