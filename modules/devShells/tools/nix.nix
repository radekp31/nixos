{pkgs}: {
  packages = with pkgs; [
    treefmt
    nixfmt
    alejandra
    nix
  ];

  hooks = {
    nixfmt.enable = true;
    yamllint.enable = true;
  };
}
