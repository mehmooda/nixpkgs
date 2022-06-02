{ lib, stdenv, fetchurl, autoreconfHook }:

stdenv.mkDerivation rec {
  version = "0.5.1";
  pname = "libmpeg2";

  src = fetchurl {
    url = "http://libmpeg2.sourceforge.net/files/${pname}-${version}.tar.gz";
    sha256 = "1m3i322n2fwgrvbs1yck7g5md1dbg22bhq5xdqmjpz5m7j4jxqny";
  };

  patches = [
    (fetchurl {
      url = "https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-libmpeg2-git/0002-libmpeg2-fix-deprecated.patch";
      sha256 = "TcoyqCpYRfT8vCbXmuT9xdmrJ8ylwq5epfqQeKAHfrY=";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-libmpeg2-git/0003-do-not-AC_C_ALWAYS_INLINE-it-redefines-inline-breaking-mingw-w64-GCC-5.1.0-C99.patch";
      sha256 = "i+t4+qwiuabDe0/yNmPNg86JREPAIzfkJ3KazYvWzOA=";
    })
  ];


  nativeBuildInputs = [ autoreconfHook ];

  # Otherwise clang fails with 'duplicate symbol ___sputc'
  buildFlags = lib.optional stdenv.isDarwin "CFLAGS=-std=gnu89";

  meta = {
    homepage = "http://libmpeg2.sourceforge.net/";
    description = "A free library for decoding mpeg-2 and mpeg-1 video streams";
    license = lib.licenses.gpl2;
    maintainers = with lib.maintainers; [ ];
    platforms = with lib.platforms; unix ++ windows;
  };
}
