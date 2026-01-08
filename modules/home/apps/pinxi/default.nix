{
  lib,
  stdenv,
  fetchFromGitea,
  perl,
}:
stdenv.mkDerivation rec {
  pname = "pinxi";
  version = "3.3.31-1";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "smxi";
    repo = "pinxi";
    # Use a tag or specific commit for reproducibility.
    # If you must use master, use a commit hash.
    rev = "master";
    # Set this to lib.fakeHash first, run it, then replace with the real hash Nix gives you.
    hash = "sha256-1z9picg4cdj1n208h4q3fjhvd51vc71sm5zq5fbiqqb33qizx1x7=";
  };

  buildInputs = [perl];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp pinxi $out/bin/
    chmod +x $out/bin/pinxi
    runHook postInstall
  '';

  meta = with lib; {
    description = "Actively maintained fork of inxi - comprehensive CLI system information tool";
    homepage = "https://codeberg.org/smxi/pinxi";
    license = licenses.gpl3Plus;
    platforms = platforms.all;
  };
}
