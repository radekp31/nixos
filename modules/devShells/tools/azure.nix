{
  pkgs25_05,
}: {
  packages = [
    (pkgs25_05.azure-cli.withExtensions [
      pkgs25_05.azure-cli-extensions.storage-preview
      pkgs25_05.azure-cli-extensions.azure-devops
      pkgs25_05.azure-cli-extensions.resource-graph
      pkgs25_05.azure-cli-extensions.ssh
      pkgs25_05.azure-cli-extensions.quota
      pkgs25_05.azure-cli-extensions.nsp
      pkgs25_05.azure-cli-extensions.kusto
      pkgs25_05.azure-cli-extensions.graphservices
      pkgs25_05.azure-cli-extensions.fzf
      pkgs25_05.azure-cli-extensions.dynatrace
    ])
  ];

  hooks = {
    yamllint.enable = true;
  };
}
