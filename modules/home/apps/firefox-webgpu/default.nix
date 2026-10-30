{
  pkgs,
  config,
  ...
}: let
  # A separate Firefox ESR instance with WebGPU on.
  # The own profile keeps the WebGPU pref out of the main profile.
  # Firefox runs one instance per profile, so this one runs next to the main one.
  # --profile takes a plain path, so profiles.ini does not change.
  profileDir = "${config.home.homeDirectory}/.mozilla/firefox/webgpu";

  firefox-webgpu = pkgs.runCommand "firefox-webgpu" {nativeBuildInputs = [pkgs.makeBinaryWrapper];} ''
    makeBinaryWrapper ${config.programs.firefox.finalPackage}/bin/firefox-esr $out/bin/firefox-webgpu \
      --add-flags "--name firefox-webgpu --profile ${profileDir}"
  '';
in {
  home.packages = [firefox-webgpu];

  # Firefox creates the profile in this directory at the first start.
  home.file.".mozilla/firefox/webgpu/user.js".text = ''
    user_pref("dom.webgpu.enabled", true);
  '';

  xdg.desktopEntries.firefox-webgpu = {
    name = "Firefox ESR (WebGPU)";
    exec = "firefox-webgpu %U";
    icon = "firefox-esr";
    categories = ["Network" "WebBrowser"];
    settings.StartupWMClass = "firefox-webgpu";
  };
}
