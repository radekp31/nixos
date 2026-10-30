{pkgs_deprecated}: {
  packages = [
    (pkgs_deprecated.azure-cli.withExtensions [
      pkgs_deprecated.azure-cli-extensions.storage-preview
      pkgs_deprecated.azure-cli-extensions.azure-devops
      pkgs_deprecated.azure-cli-extensions.resource-graph
      pkgs_deprecated.azure-cli-extensions.ssh
      pkgs_deprecated.azure-cli-extensions.quota
      pkgs_deprecated.azure-cli-extensions.nsp
      pkgs_deprecated.azure-cli-extensions.kusto
      pkgs_deprecated.azure-cli-extensions.graphservices
      pkgs_deprecated.azure-cli-extensions.fzf
      pkgs_deprecated.azure-cli-extensions.dynatrace
    ])
  ];

  hooks = {
    yamllint.enable = true;
  };
}
