{pkgs, ...}: {
  boot.kernelModules = ["btusb" "uhid"];
  boot.kernelParams = ["usbcore.autosuspend=-1"];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # This is crucial for ZMK / BLE discovery
        Experimental = false;
        # Allows the adapter to see LE devices more easily
        MultiProfile = "multiple";
      };
    };
  };
}
