{lib, stdenv, fetchurl, libogg, libvorbis, pkg-config, autoreconfHook, fetchpatch }:

stdenv.mkDerivation rec {
  pname = "libtheora";
  version = "1.1.1";

  src = fetchurl {
    url = "https://downloads.xiph.org/releases/theora/${pname}-${version}.tar.gz";
    sha256 = "0swiaj8987n995rc7hw0asvpwhhzpjiws8kr3s6r44bqqib2k5a0";
  };

  patches = [
    # fix error in autoconf scripts
    (fetchpatch {
      url = "https://github.com/xiph/theora/commit/28cc6dbd9b2a141df94f60993256a5fca368fa54.diff";
      sha256 = "16jqrq4h1b3krj609vbpzd5845cvkbh3mwmjrcdg35m490p19x9k";
    })
#    (fetchpatch {
#      url = "https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-libtheora/libtheora-1.1.1-libpng16.patch";
#      sha256 = "MVy9IlSgPB9IGvAiVtmI7bR+FpaMEY9KyOK3clU5enw=";
#    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/msys2/MINGW-packages/master/mingw-w64-libtheora/001-example.patch";
      sha256 = "5627d26c3316fef71bca037e1834bcba063dbf949ea9293820f0e68b13641105";
    })
  ];
 
  postPatch = ''
  sed -i "s,EXPORTS,," "win32/xmingw32/libtheoradec-all.def"
  sed -i "s,EXPORTS,," "win32/xmingw32/libtheoraenc-all.def"
  '';

  outputs = [ "out" "dev" "devdoc" ];
  outputDoc = "devdoc";

  nativeBuildInputs = [ pkg-config autoreconfHook ];
  propagatedBuildInputs = [ libogg libvorbis ];

  meta = with lib; {
    homepage = "https://www.theora.org/";
    description = "Library for Theora, a free and open video compression format";
    license = licenses.bsd3;
    maintainers = with maintainers; [ spwhitt ];
    platforms = platforms.unix ++ platforms.windows;
  };
}
