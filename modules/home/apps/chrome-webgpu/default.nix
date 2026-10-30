{pkgs, ...}: let
  # Google Chrome with WebGPU on the NVIDIA Vulkan driver.
  # Without these flags, Dawn finds only the slow OpenGL ES compatibility
  # adapter, and WebGPU games are choppy.
  # VK_DRIVER_FILES hides Mesa's CPU driver (llvmpipe) from Vulkan.
  # ANGLE on Vulkan and X11 (XWayland) make Dawn expose the Vulkan adapter.
  # Chrome reads flags only at a fresh start: a launch while Chrome runs
  # opens a window in the old instance, and the Relaunch button drops the flags.
  chrome-webgpu = pkgs.runCommand "chrome-webgpu" {nativeBuildInputs = [pkgs.makeBinaryWrapper];} ''
    makeBinaryWrapper ${pkgs.google-chrome}/bin/google-chrome-stable $out/bin/chrome-webgpu \
      --set VK_DRIVER_FILES /run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json \
      --add-flags "--enable-unsafe-webgpu --enable-features=Vulkan,VulkanFromANGLE,DefaultANGLEVulkan --use-angle=vulkan --ozone-platform=x11"
  '';
in {
  home.packages = [chrome-webgpu];

  xdg.desktopEntries.chrome-webgpu = {
    name = "Google Chrome (WebGPU)";
    exec = "chrome-webgpu %U";
    icon = "${pkgs.google-chrome}/share/icons/hicolor/256x256/apps/google-chrome.png";
    categories = ["Network" "WebBrowser"];
  };
}
