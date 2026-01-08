{
  lib,
  stdenv,
  fetchurl,
  perl,
}:
stdenv.mkDerivation rec {
  pname = "pinxi";
  version = "3.3.31-1";

  src = fetchurl {
    url = "https://codeberg.org/api/v1/repos/smxi/pinxi/archive/master.tar.gz";
    sha256 = "sha256-1icncbhwyfwvmcs1jnq67m4q9vsxg6p41s012dx8c2yjhl40c8aq=";
  };

  buildInputs = [perl];

  # pinxi is a Perl script, no compilation needed
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp pinxi $out/bin/
    chmod +x $out/bin/pinxi
  '';

  meta = with lib; {
    description = "Actively maintained fork of inxi - comprehensive CLI system information tool";
    homepage = "https://codeberg.org/smxi/pinxi";
    license = licenses.gpl3Plus;
    maintainers = [];
    platforms = platforms.all;
  };
}
