{pkgs, ...}: {
  # ghostcat devbox prerequisites — NATIVE=0 (podman machine / QEMU/KVM path)
  # https://github.com/ghostcat/ghostcat-scripts/ai/docker/ghostcat-claude-devbox

  virtualisation.podman.enable = true;

  # Tools checked by scripts/check-prereqs.sh via `command -v`
  environment.systemPackages = with pkgs; [
    podman-compose
    jq
    gnumake
    gvproxy   # podman machine network proxy
    virtiofsd # podman machine filesystem share
    qemu      # provides qemu-system-x86_64
    shadow    # provides sg/newgrp — activates kvm group without re-login
  ];

  # Persistent /dev/kvm ownership so QEMU can open it after WSL restarts
  services.udev.extraRules = ''
    KERNEL=="kvm", GROUP="kvm", MODE="0660"
  '';
}
