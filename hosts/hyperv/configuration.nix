{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ../common/default.nix
    ../common/profiles/desktop.nix
    ../common/profiles/hyperv.nix
    ../../modules/system/apps/desktop/xfce
  ];

  boot.plymouth.enable = true;
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  services.displayManager.defaultSession = "xfce";

  services.xrdp.defaultWindowManager = "xfce4-session";

  networking.hostName = "nixos-hyperv";
  time.timeZone = "Europe/Amsterdam";

  boot.kernel.sysctl."net.ipv6.conf.eth0.disable_ipv6" = true;

  # Enable SSH
  services.openssh.enable = true;

  nixpkgs.config.allowUnfree = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.firefox.enable = true;

  programs.fzf = {
    keybindings = true;
    fuzzyCompletion = true;
  };

  programs.bash = {
    completion.enable = true;
    enableLsColors = true;
    shellInit = ''
      bind "set show-all-if-ambiguous on"
      bind "TAB:menu-complete"
      source ${pkgs.git}/share/git/contrib/completion/git-prompt.sh
    '';
    interactiveShellInit = ''
      if [ "$TERM" = "xterm" ] || [ "$TERM" = "xterm-256color" ]; then
        xrdb -merge /etc/X11/Xresources
      fi
    '';
  };

  # SSH askpass for X11
  programs.ssh.askPassword = "${pkgs.x11_ssh_askpass}/libexec/x11_ssh_askpass";

  services.dbus.enable = true;
  services.gnome.core-utilities.enable = true;

  environment.etc."X11/Xresources".text = ''
    xterm*background: black
    xterm*foreground: white
    xterm*faceName: VeraMono
    xterm*faceSize: 13
    xterm*saveLines: 4096
    xterm*scrollBar: true
    xterm*rightScrollBar: true
    xterm*renderFont: true
  '';

  environment.systemPackages = with pkgs; [
    jq
  ];

  system.stateVersion = "24.11";
}
