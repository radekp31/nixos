{
  pkgs,
  pkgs25_05,
  ...
}:
pkgs.mkShell {
  packages = [
    pkgs.kubectl
    pkgs.terraform
    pkgs.awscli2
    pkgs.google-cloud-sdk
    pkgs25_05.azure-cli
  ];
}
