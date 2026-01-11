{
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops #try <sops-nix/modules/sops>
  ];

  services.openssh = {
    enable = true;
  };

  environment.sessionVariables = {
    SOPS_AGE_KEY_FILE = "/var/lib/sops-nix/keys.txt";
  };

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;

    age = {
      #automatically import host SSH keys as age keys
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

      #use an age key that is expected to already be in the filesystem
      keyFile = "/var/lib/sops-nix/keys.txt";

      #generate a new key if the key specified above does not exist
      generateKey = true;
    };

    #This should represent the structure of the secrets/secrets.yaml
    secrets = {
      #"radekp-password" = {
      #  sopsFile = ./secrets/secrets.yaml;
      #  #owner = "radekp";
      #  owner =
      #    if config.networking.hostName == "nixos-desktop"
      #    then "radekp"
      #    else "root";
      #  mode = "0400";
      #  format = "yaml";
      #};
      "IPs/pinas" = {
        sopsFile = ./secrets/secrets.yaml;
        owner =
          if (config.users.users ? radekp) && (config.users.users.radekp.enable == true)
          then "radekp"
          else "root";
        mode = "0400";
        format = "yaml";
      };
    };
  };
}
