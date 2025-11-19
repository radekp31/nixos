# treefmt.nix
{ ...}: {
  # Used to find the project root
  #projectRootFile = "../../../flake.nix";
  projectRootFile = "flake.nix";

  # Enable the terraform formatter
  # List of supported formatters: https://github.com/numtide/treefmt-nix
  programs.alejandra.enable = true;
  #programs.alejandra.package = pkgs.alejandra;
  programs.prettier.enable = true;
  programs.deadnix.enable = true;
  #programs.dockerfmt.enable = true;
  #programs.terraform.enable = true;
  #programs.tomlsort.enable = true;

  # Override the default package
  #programs.terraform.package = pkgs.terraform_1;

  # Excludes files you dont want to format
  #settings.formatter.terraform.excludes = [ "hello.tf" ];
}
