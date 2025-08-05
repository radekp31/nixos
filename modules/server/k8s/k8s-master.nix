{ config, lib, pkgs, ... }:

{
  systemd.services.setup-local-ip = {

    description = "Add current IP into /etc/hosts file";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    enable = true;

    path = with pkgs; [
      iproute2
      gawk
      gnused
      gnugrep
      coreutils
    ];

    script = ''
      LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
      sed -i '/api\.kube/d' /etc/hosts
      echo "$LOCAL_IP api.kube" >> /etc/hosts
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
    };

  };

  system.activationScripts.enableLocalIPService = {
    text = ''
      systemctl enable setup-local-ip 2>/dev/null || true
      systemctl restart setup-local-ip 2>/dev/null || true
    '';
  };

  system.activationScripts.enablecontainerd = {
    text = ''
      systemctl enable containerd 2>/dev/null || true
      systemctl restart containerd 2>/dev/null || true
    '';
  };

  # kubectl has to be run as root
  users.users.root.extraGroups = [ "kubernetes" ];

  # k8s node needs unique hostname in the cluster
  networking.hostName = "nixkube-master";

  # optional alias for kubectl
  programs.bash.shellAliases = {
    k = "kubectl";
  };

  # enable containerd
  # see system.activation scripts
  # TODO - this doesnt get restarted on rebuild
  # TODO - create config that will restart folowing on rebuild:
  # TODO - kube*.service , flannel.service, certmgr.service, containerd.service, cfssl.service
  virtualisation.containerd.enable = true;

  # enable kubelet
  services.kubernetes.kubelet = {
    cni.packages = [ pkgs.flannel ];
    extraOpts = "--fail-swap-on=false"; #Optional, but handy just in case you forget to disable swap
  };

  # setup kubernetes cluster
  services.kubernetes = {
    roles = [ "master" "node" ];
    masterAddress = "api.kube";
    addons.dns.enable = true; # this enables coredns
    flannel.enable = true;
  };

  # setup admin.kubeconfig, can be changed later
  environment.variables = {
    KUBECONFIG = "/etc/kubernetes/cluster-admin.kubeconfig";
  };

  # install required packages
  environment.systemPackages = with pkgs; [
    dbus
    jq
    kubectl
    kubernetes
    kompose
    containerd
    runc
    cri-tools
    nettools
  ];

  # setup firewall
  networking.firewall.allowedTCPPorts = [ 2379 2380 6443 8888 10248 10249 10250 10251 10252 10256 37437 ];
  networking.firewall.allowedUDPPorts = [ 2379 2380 6443 8888 10248 10249 10250 10251 10252 10256 37437 ];

}

