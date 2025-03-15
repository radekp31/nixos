{ inputs, config, ... }:

{

  imports = [
    inputs.sops-nix.nixosModules.sops #try <sops-nix/modules/sops>
  ];

  services.openssh = {
    enable = true;
  };

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;

    age = {
      #automatically import host SSH keys as age keys
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      #use an age key that is expected to already be in the filesystem
      #keyFile = "/home/user/.config/sops/age/keys.txt";
      keyFile = "/var/lib/sops-nix/keys.txt";

      #generate a new key if the key specified above does not exist
      generateKey = true;

    };

    #This should represent the structure of the secrets/secrets.yaml
    #secrets = {
    #  radekp-password = {};
    #  ssh-keys = {};
    #};
    secrets = {
      "radekp-password" = {
        #sopsFile = ../../secrets/secrets.yaml;
        #owner = "radekp";
        #mode = "0400";
      };

      "ssh-keys/contabovps1" = {
        #sopsFile = ../../secrets/secrets.yaml;
        #owner = "radekp";  
        #mode = "0400";     
      };

      "ssh-keys/nixos-desktop" = {
        #sopsFile = ../../secrets/secrets.yaml;
        #owner = "radekp";
        #mode = "0400";
      };
    };
  };

}
