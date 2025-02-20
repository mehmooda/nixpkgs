{ lib
, stdenv
, fetchurl
, installShellFiles
, pkg-config

# Optional dependencies
, enableApp ? with stdenv.hostPlatform; !isWindows && !isStatic
, c-ares, libev, openssl, zlib
, enableAsioLib ? false, boost
, enableGetAssets ? false, libxml2
, enableHpack ? false, jansson
, enableJemalloc ? false, jemalloc
, enablePython ? false, python3Packages, ncurses

# Unit tests ; we have to set TZDIR, which is a GNUism.
, enableTests ? (stdenv.hostPlatform.isGnu && stdenv.hostPlatform == stdenv.buildPlatform), cunit, tzdata

# downstream dependencies, for testing
, curl
, libsoup
}:

# Note: this package is used for bootstrapping fetchurl, and thus cannot use fetchpatch!
# All mutable patches (generated by GitHub or cgit) that are needed here
# should be included directly in Nixpkgs as files.

assert enableGetAssets -> enableApp;
assert enableHpack -> enableApp;
assert enableJemalloc -> enableApp;

stdenv.mkDerivation rec {
  pname = "nghttp2";
  version = "1.47.0";

  src = fetchurl {
    url = "https://github.com/${pname}/${pname}/releases/download/v${version}/${pname}-${version}.tar.bz2";
    sha256 = "11d6w8iqrhnxmjd9ss9fzf66f7a32d48h2ihyk1580lg8d3rkj07";
  };

  outputs = [ "bin" "out" "dev" "lib" ]
    ++ lib.optionals (enablePython) [ "python" ];

  nativeBuildInputs = [ pkg-config ]
    ++ lib.optionals (enableApp) [ installShellFiles ]
    ++ lib.optionals (enablePython) [ python3Packages.cython ];

  buildInputs = lib.optionals enableApp [ c-ares libev openssl zlib ]
    ++ lib.optionals (enableAsioLib) [ boost ]
    ++ lib.optionals (enableGetAssets) [ libxml2 ]
    ++ lib.optionals (enableHpack) [ jansson ]
    ++ lib.optionals (enableJemalloc) [ jemalloc ]
    ++ lib.optionals (enablePython) [ python3Packages.python ncurses python3Packages.setuptools ];

  enableParallelBuilding = true;

  configureFlags = [
    "--disable-examples"
    (lib.enableFeature enableApp "app")
  ] ++ lib.optionals (enableAsioLib) [ "--enable-asio-lib" "--with-boost-libdir=${boost}/lib" ]
    ++ lib.optionals (enablePython) [ "--with-cython=${python3Packages.cython}/bin/cython" ];

  # Unit tests require CUnit and setting TZDIR environment variable
  doCheck = enableTests;
  checkInputs = lib.optionals (enableTests) [ cunit tzdata ];
  preCheck = lib.optionalString (enableTests) ''
    export TZDIR=${tzdata}/share/zoneinfo
  '';

  preInstall = lib.optionalString (enablePython) ''
    mkdir -p $out/${python3Packages.python.sitePackages}
    # convince installer it's ok to install here
    export PYTHONPATH="$PYTHONPATH:$out/${python3Packages.python.sitePackages}"
  '';
  postInstall = lib.optionalString (enablePython) ''
    mkdir -p $python/${python3Packages.python.sitePackages}
    mv $out/${python3Packages.python.sitePackages}/* $python/${python3Packages.python.sitePackages}
    rm -r $out/lib
  '' + lib.optionalString (enableApp) ''
    installShellCompletion --bash doc/bash_completion/{h2load,nghttp,nghttpd,nghttpx}
  '';

  passthru.tests = {
    inherit curl libsoup;
  };

  meta = with lib; {
    description = "HTTP/2 C library and tools";
    longDescription = ''
      nghttp2 is an implementation of the HyperText Transfer Protocol version 2 in C.
      The framing layer of HTTP/2 is implemented as a reusable C library. On top of that,
      we have implemented an HTTP/2 client, server and proxy. We have also developed
      load test and benchmarking tools for HTTP/2.
      An HPACK encoder and decoder are available as a public API.
      We have Python bindings of this library, but we do not have full code coverage yet.
      An experimental high level C++ library is also available.
    '';

    homepage = "https://nghttp2.org/";
    changelog = "https://github.com/nghttp2/nghttp2/releases/tag/v${version}";
    # News articles with changes summary can be found here: https://nghttp2.org/blog/archives/
    license = licenses.mit;
    maintainers = with maintainers; [ c0bw3b ];
    platforms = platforms.all;
  };
}
