{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops #try <sops-nix/modules/sops>
  ];

  services.nginx = {
    enable = true;
    virtualHosts.default = {
      default = true;
      root = "${pkgs.nginx}/html";
      #locations."/".index = "index.html";
      #locations."/".return = "200 \"Hello from Nixy!\"";
    };
  };

  # Open port 22 in the firewall -done
  # Set default inbound to drop -done
  # allow inbound 22,80 from specific IP -done
  # allow related and established inbound -done
  # allow related and established outbound -done
  # Reject all other inbound traffic to 22, 80 -done
  # Allow out 53 -done
  # Allow out 123 -done
  # setup DoT or DoH - PENDING

  networking.firewall = {
    # Set default inbound policy to drop
    allowedTCPPorts = [];
    allowedUDPPorts = [];

    # Enable the firewall
    enable = true;

    # Allow established and related connections
    # Backup
    ## Allow inbound SSH (22) and HTTP (80) from a specific IP
    #iptables -A INPUT -p tcp --dport 22 -s "$(cat ${config.sops.secrets."IPs/homenetwork".path})" -j ACCEPT
    #iptables -A INPUT -p tcp --dport 80 -s "$(cat ${config.sops.secrets."IPs/homenetwork".path})" -j ACCEPT

    extraCommands = ''
      # Allow inbound SSH (22) and HTTP (80) from a specific IP
      iptables -A INPUT -p tcp --dport 22 -s "$(cat ${config.sops.secrets."IPs/homenetwork".path})" -j ACCEPT
      iptables -A INPUT -p tcp --dport 80 -s "$(cat ${config.sops.secrets."IPs/homenetwork".path})" -j ACCEPT

      # Allow established and related connections inbound
      iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

      # Reject (with proper ICMP response) all other traffic to ports 22 and 80
      iptables -A INPUT -p tcp --dport 22 -j REJECT
      iptables -A INPUT -p tcp --dport 80 -j REJECT

      # Allow established and related connections outbound
      iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

      # Allow outbound DNS (53) and NTP (123)
      iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
      iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
      iptables -A OUTPUT -p udp --dport 123 -j ACCEPT
    '';

    extraStopCommands = ''
      # Clean up custom rules when firewall is stopped
      iptables -F INPUT
      iptables -F OUTPUT
    '';

    # The NixOS default is to blacklist all traffic and allow specific ports
    # Default policy is to drop new incoming connections
    rejectPackets = true;
  };
}
