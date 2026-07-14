{pkgs ? import <nixpkgs> {}}:
(pkgs.buildFHSEnv {
  name = "rkllm-fhs-env";
  targetPkgs = pkgs:
    with pkgs; [
      (python312.withPackages (ps:
        with ps; [
          pip
          virtualenv
          numpy
          playwright
          click
          httpx
          aiofiles
        ]))
      glibc
      zlib
      stdenv.cc.cc.lib
      chromium
    ];
  runScript = "bash";
}).env
