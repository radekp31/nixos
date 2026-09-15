# Secrets for this host.
#
# sops-nix decrypts at activation with the ed25519 ssh host key.
# sops.age.sshKeyPaths finds that key by itself whenever
# services.openssh.enable is true, so this file declares no key source.
{inputs, ...}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops.defaultSopsFile = ./secrets/secrets.yaml;

  # Declare each secret next to the option that reads it.
  # This one proves the decryption works end to end. Keep it.
  sops.secrets.test_secret.owner = "radekp";
}
