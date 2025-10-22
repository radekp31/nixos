{
  config,
  pkgs,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: {
      # Override openrgb to use MbedTLS 3 instead of MbedTLS 2
      openrgb = prev.openrgb.overrideAttrs (oldAttrs: {
        buildInputs =
          builtins.map (
            dep:
              if dep.pname or "" == "mbedtls"
              then final.mbedtls
              else dep
          )
          oldAttrs.buildInputs;
      });
    })
  ];

  # Enable the openrgb service
  services.hardware.openrgb.enable = true;
}
