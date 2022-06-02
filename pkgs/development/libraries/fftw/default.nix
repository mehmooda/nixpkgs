{ fetchurl
, stdenv
, lib
, gfortran
, perl
, llvmPackages
, precision ? "double"
, enableAvx ? stdenv.hostPlatform.avxSupport
, enableAvx2 ? stdenv.hostPlatform.avx2Support
, enableAvx512 ? stdenv.hostPlatform.avx512Support
, enableFma ? stdenv.hostPlatform.fmaSupport
, enableMpi ? false
, mpi
, withDoc ? stdenv.cc.isGNU && !stdenv.hostPlatform.isWindows
, cmake
}:

with lib;

assert elem precision [ "single" "double" "long-double" "quad-precision" ];

stdenv.mkDerivation rec {
  pname = "fftw-${precision}";
  version = "3.3.10";

  src = fetchurl {
    urls = [
      "https://fftw.org/fftw-${version}.tar.gz"
      "ftp://ftp.fftw.org/pub/fftw/fftw-${version}.tar.gz"
    ];
    sha256 = "sha256-VskyVJhSzdz6/as4ILAgDHdCZ1vpIXnlnmIVs0DiZGc=";
  };

  outputs = [ "out" "dev" ];
  #  ++ optionals withDoc [ "man" "info"]; # it's dev-doc only
  outputBin = "dev"; # fftw-wisdom

  nativeBuildInputs = optionals (!stdenv.hostPlatform.isWindows) [ gfortran ] ++ [ cmake ];

  buildInputs = optionals stdenv.cc.isClang [
    # TODO: This may mismatch the LLVM version sin the stdenv, see #79818.
    llvmPackages.openmp
  ] ++ optional enableMpi mpi;


  cmakeFlags =
#   Defaults
#    "-DBUILD_SHARED_LIBS=ON"
#    "-DBUILD_TESTS=ON"
#    "-DENABLE_OPENMP=OFF"
  [ "-DENABLE_THREADS=ON" "-DWITH_COMBINED_THREADS=ON" ]
#    "-DWITH_COMBINED_THREADS=OFF"
#    "-DENABLE_FLOAT=OFF"
  ++ optional (precision == "single") "-DENABLE_FLOAT=ON"
#    "-DENABLE_LONG_DOUBLE=OFF"
  ++ optional (precision == "long-double") "-DENABLE_LONG_DOUBLE=ON"
#    "-DENABLE_QUAD_PRECISION=OFF"
  ++ optional (precision == "quad-precising") "-DENABLE_QUAD_PRECISION=ON"
#    "-DENABLE_SSE=OFF"
#    "-DENABLE_SSE2=OFF"
  ++ optionals (stdenv.isx86_64 && (precision == "single" || precision == "double") ) [ "-DENABLE_SSE=ON" "-DENABLE_SSE2=ON" ]
#    "-DENABLE_AVX=OFF"
  ++ optional enableAvx "-DENABLE_AVX=ON"
#    "-DENABLE_AVX2=OFF"
  ++ optional enableAvx2 "-DENABLE_AVX2=ON"
#    "-DDISABLE_FORTRAN=OFF"
  ++ optional stdenv.hostPlatform.isWindows "-DWITH_OUR_MALLOC=ON"
  ;

#    ++ optional enableAvx512 "--enable-avx512"
#    ++ optional enableFma "--enable-fma"
#    ++ optional (!stdenv.hostPlatform.isWindows) "--enable-openmp"
#    ++ optional enableMpi "--enable-mpi"
    # doc generation causes Fortran wrapper generation which hard-codes gcc
#    ++ optional (!withDoc) "--disable-doc";

  preConfigure = if stdenv.hostPlatform.isWindows then ''
    echo "add_definitions ("-DWITH_OUR_MALLOC")" >> CMakeLists.txt
  '' else null;

  enableParallelBuilding = true;

  checkInputs = [ perl ];

  meta = with lib; {
    description = "Fastest Fourier Transform in the West library";
    homepage = "http://www.fftw.org/";
    license = licenses.gpl2Plus;
    maintainers = [ maintainers.spwhitt ];
    platforms = platforms.unix ++ platforms.windows;
  };
}
