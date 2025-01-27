{ lib, stdenv, fetchFromGitHub, autoreconfHook, libtool
, threadingSupport ? true # multi-threading
, openglSupport ? false, freeglut, libGL, libGLU # OpenGL (required for vwebp)
, pngSupport ? true, libpng # PNG image format
, jpegSupport ? true, libjpeg # JPEG image format
, tiffSupport ? true, libtiff # TIFF image format
, gifSupport ? true && !stdenv.hostPlatform.isWindows, giflib # GIF image format
#, wicSupport ? true # Windows Imaging Component
, alignedSupport ? false # Force aligned memory operations
, swap16bitcspSupport ? false # Byte swap for 16bit color spaces
, experimentalSupport ? false # Experimental code
, libwebpmuxSupport ? true # Build libwebpmux
, libwebpdemuxSupport ? true # Build libwebpdemux
, libwebpdecoderSupport ? true # Build libwebpdecoder
}:

let
  mkFlag = optSet: flag: if optSet then "--enable-${flag}" else "--disable-${flag}";
in

with lib;
stdenv.mkDerivation rec {
  pname = "libwebp";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner  = "webmproject";
    repo   = pname;
    rev    = "v${version}";
    hash   = "sha256-KrvB5d3KNmujbfekWaevz2JZrWtK3PjEG9NEzRBYIDw=";
  };

  prePatch = "patchShebangs .";

  configureFlags = [
    (mkFlag threadingSupport "threading")
    (mkFlag openglSupport "gl")
    (mkFlag pngSupport "png")
    (mkFlag jpegSupport "jpeg")
    (mkFlag tiffSupport "tiff")
    (mkFlag gifSupport "gif")
    #(mkFlag (wicSupport && stdenv.isCygwin) "wic")
    (mkFlag alignedSupport "aligned")
    (mkFlag swap16bitcspSupport "swap-16bit-csp")
    (mkFlag experimentalSupport "experimental")
    (mkFlag libwebpmuxSupport "libwebpmux")
    (mkFlag libwebpdemuxSupport "libwebpdemux")
    (mkFlag libwebpdecoderSupport "libwebpdecoder")
  ];

  nativeBuildInputs = [ autoreconfHook libtool ];
  buildInputs = [ ]
    ++ optionals openglSupport [ freeglut libGL libGLU ]
    ++ optional pngSupport libpng
    ++ optional jpegSupport libjpeg
    ++ optional tiffSupport libtiff
    ++ optional gifSupport giflib;

  enableParallelBuilding = true;

  meta = {
    description = "Tools and library for the WebP image format";
    homepage = "https://developers.google.com/speed/webp/";
    license = licenses.bsd3;
    platforms = platforms.all;
    maintainers = with maintainers; [ codyopel ];
  };
}
