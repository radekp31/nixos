{inputs, ...}: {
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  home.sessionVariables = {
    SDL_VIDEODRIVER = "wayland";
    DEFAULT_BROWSER = "zen";
    BROWSER = "zen";
  };

  programs.zen-browser = {
    enable = true;
    # Optional: You can manage settings just like Firefox
    policies = {
      DisableTelemetry = true;
      OfferToSaveLogins = false;
    };
  };
}
