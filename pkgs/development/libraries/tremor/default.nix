{ lib, stdenv, fetchFromGitLab, autoreconfHook, pkg-config, libogg }:

stdenv.mkDerivation {
  pname = "tremor";
  version = "unstable-2018-03-16";

  src = fetchFromGitLab {
    owner = "xiph";
    repo = "tremor";
    domain = "gitlab.xiph.org";
    rev = "562307a4a7082e24553f3d2c55dab397a17c4b4f";
    sha256 = "0m07gq4zfgigsiz8b518xyb19v7qqp76qmp7lb262825vkqzl3zq";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [ autoreconfHook pkg-config ];
  propagatedBuildInputs = [ libogg ];

  preConfigure = ''
    sed -i /XIPH_PATH_OGG/d configure
  '';

  postConfigure = ''
    sed -i.bak -e "s/\(allow_undefined=\)yes/\1no/" libtool
  '';

  meta = {
    homepage = "https://xiph.org/tremor/";
    description = "Fixed-point version of the Ogg Vorbis decoder";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };
}

