# modules/default.nix
{...}: {
  # Import other modules and pass the variables
  imports = [
    ./apps/git/default.nix
    #    ./apps/vbox/vbox.nix
    ./apps/openrgb/openrgb.nix
    ./usb/usb.nix
  ];
}
