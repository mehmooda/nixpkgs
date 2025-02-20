{ lib, stdenv, fetchFromGitHub, autoreconfHook, autogen, flac, libogg, libopus, libvorbis, pkg-config, python3
, Carbon, AudioToolbox
}:

stdenv.mkDerivation rec {
  pname = "libsndfile";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = version;
    sha256 = "sha256-bhIXVSKuUnUzs5aaLDHt21RcnqekEpLU414sFtl2Lro=";
  };

  nativeBuildInputs = [ autoreconfHook autogen pkg-config python3 ];
  buildInputs = [ flac libogg libopus libvorbis ]
    ++ lib.optionals stdenv.isDarwin [ Carbon AudioToolbox ];

  enableParallelBuilding = true;

  outputs = [ "bin" "dev" "out" "man" "doc" ];

  # need headers from the Carbon.framework in /System/Library/Frameworks to
  # compile this on darwin -- not sure how to handle
  preConfigure = lib.optionalString stdenv.isDarwin
    ''
      NIX_CFLAGS_COMPILE+=" -I$SDKROOT/System/Library/Frameworks/Carbon.framework/Versions/A/Headers"
    '';

  # Needed on Darwin.
  NIX_CFLAGS_LINK = "-logg -lvorbis";

  meta = with lib; {
    description = "A C library for reading and writing files containing sampled sound";
    homepage    = "https://libsndfile.github.io/libsndfile/";
    license     = licenses.lgpl2Plus;
    maintainers = with maintainers; [ lovek323 ];
    platforms   = platforms.unix ++ platforms.windows;

    longDescription = ''
      Libsndfile is a C library for reading and writing files containing
      sampled sound (such as MS Windows WAV and the Apple/SGI AIFF format)
      through one standard library interface.  It is released in source
      code format under the GNU Lesser General Public License.

      The library was written to compile and run on a Linux system but
      should compile and run on just about any Unix (including macOS).
      There are also pre-compiled binaries available for 32 and 64 bit
      windows.

      It was designed to handle both little-endian (such as WAV) and
      big-endian (such as AIFF) data, and to compile and run correctly on
      little-endian (such as Intel and DEC/Compaq Alpha) processor systems
      as well as big-endian processor systems such as Motorola 68k, Power
      PC, MIPS and SPARC.  Hopefully the design of the library will also
      make it easy to extend for reading and writing new sound file
      formats.
    '';
  };
}
