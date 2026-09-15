{
  inputs,
  osConfig,
  ...
}: let
  flavor = osConfig.my.theme.catppuccin;
in {
  imports = [inputs.catppuccin.homeModules.catppuccin];
  catppuccin = {
    enable = true;
    flavor = flavor;
    foot.enable = false; # broken upstream — colors are hardcoded into config now
    bat = {
      enable = true;
      flavor = flavor;
    };
    btop = {
      enable = true;
      flavor = flavor;
    };
    fzf = {
      enable = true;
      flavor = flavor;
    };
  };
}
