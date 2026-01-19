{ pkgs }:
{
  packages = [
    (pkgs.python313.withPackages (ps: with ps; [
      openpyxl
      collections-extended
      pandas
      numpy
      pip
      pytest
    ]))
  ];

  hooks = {
    black.enable = true;
    pylint.enable = true;
    mypy.enable = true;
  };
}

