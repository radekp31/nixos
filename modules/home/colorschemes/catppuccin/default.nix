{
  inputs,
  osConfig,
  ...
}: let
  catppuccinMacchiato =
    if (osConfig ? catppuccinTheme)
    then osConfig.catppuccinTheme
    else "macchiato";
in {
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  catppuccin = {
    enable = true;
    flavor = catppuccinMacchiato;

    foot = {
      enable = true;
      flavor = catppuccinMacchiato;
    };

    bat = {
      enable = true;
      flavor = catppuccinMacchiato;
    };

    btop = {
      enable = true;
      flavor = catppuccinMacchiato;
    };

    fzf = {
      enable = true;
      flavor = catppuccinMacchiato;
    };
  };
}
