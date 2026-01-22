{pkgs}: {
  packages = with pkgs; [
    treefmt
    nixfmt
    alejandra
    nix
    detect-secrets
    trufflehog
  ];

  hooks = {
    nixfmt.enable = true;
    yamllint.enable = true;
  };
}
