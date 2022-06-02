{lib, stdenv, fetchurl, pkg-config
, autoreconfHook
, libdvdread}:

stdenv.mkDerivation rec {
  pname = "libdvdnav";
  version = "6.1.1";

  src = fetchurl {
    url = "http://get.videolan.org/libdvdnav/${version}/${pname}-${version}.tar.bz2";
    sha256 = "sha256-wZGnR1lH0yP/doDPksD7G+gjdwGIXzdlbGTQTpjRjUg=";
  };

  postPatch = ''
    sed 's/libdvdnav_la_LDFLAGS = /libdvdnav_la_LDFLAGS = -no-undefined /' -i Makefile.am
  '';

  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [libdvdread];

  meta = {
    homepage = "http://dvdnav.mplayerhq.hu/";
    description = "A library that implements DVD navigation features such as DVD menus";
    license = lib.licenses.gpl2;
    maintainers = [ lib.maintainers.wmertens ];
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };

  passthru = { inherit libdvdread; };
}
