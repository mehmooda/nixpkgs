{ lib, stdenv, fetchurl, pkgsBuildBuild }:

stdenv.mkDerivation rec {
  pname = "libmodplug";
  version = "0.8.9.0";

  preConfigure = ''
     substituteInPlace configure \
        --replace ' -mmacosx-version-min=10.5' "" \
        --replace /usr/bin/file ${pkgsBuildBuild.file}/bin/file
  '';

  meta = with lib; {
    description = "MOD playing library";
    homepage    = "http://modplug-xmms.sourceforge.net/";
    license     = licenses.publicDomain;
    platforms   = platforms.unix ++ platforms.windows;
    maintainers = with maintainers; [ raskin ];
  };

  src = fetchurl {
    url = "mirror://sourceforge/project/modplug-xmms/libmodplug/${version}/${pname}-${version}.tar.gz";
    sha256 = "1pnri98a603xk47smnxr551svbmgbzcw018mq1k6srbrq6kaaz25";
  };
}
