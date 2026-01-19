{ pkgs }:
{
  packages = with pkgs; [
    nixfmt
    alejandra
    nix
  ];

  hooks = {
    nixfmt.enable = true;
    yamllint.enable = true;
  };
}

