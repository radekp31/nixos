{
  python = {
    black.enable = true;
    pylint.enable = true;
    mypy.enable = true;
  };

  nix = {
    nixfmt.enable = true;
    yamllint.enable = true;
  };

  devops = {
    yamllint.enable = true;
    end-of-file-fixer.enable = true;
  };

  minimal = {
    trailing-whitespace.enable = true;
    end-of-file-fixer.enable = true;
    check-yaml.enable = true;
  };
}
