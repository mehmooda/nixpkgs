{ lib, stdenv, fetchurl, libxml2, pkg-config
, compressionSupport ? true, zlib ? null
, sslSupport ? true, openssl ? null
, static ? stdenv.hostPlatform.isStatic
, shared ? !stdenv.hostPlatform.isStatic
, libtool
, which
, automake
, autoconf
}:

assert compressionSupport -> zlib != null;
assert sslSupport -> openssl != null;
assert static || shared;

let
   inherit (lib) optionals;
in

stdenv.mkDerivation rec {
  version = "0.32.2";
  pname = "neon";

  src = fetchurl {
    url = "https://notroj.github.io/${pname}/${pname}-${version}.tar.gz";
    sha256 = "sha256-mGVmRoxilfxdD7FBpZgeMcn4LuOOk4N0q+2Ece8vsoY=";
  };

  patches = optionals stdenv.isDarwin [ ./darwin-fix-configure.patch ];

  # Package is checking build OS rather than hostOS. But it's still broken. So just add -lws2_32 to LDFLAGS
  postPatch = if stdenv.hostPlatform.isWindows then ''
    sed -e 's/AC_PATH_PROG/AC_CHECK_TOOL/' -e 's/$ne_cv_os_uname/$ac_cv_env_host_alias_value/' -e 's/MINGW\*/x86_64-w64-mingw32/' -i macros/neon.m4
    sed -e 's/-no-undefined/-no-undefined -lws2_32/' -i src/Makefile.in
  '' else null;

  nativeBuildInputs = [ pkg-config ]
    ++ lib.optionals stdenv.hostPlatform.isWindows [ libtool which automake autoconf ];
  buildInputs = [libxml2 openssl]
    ++ lib.optional compressionSupport zlib;

  preConfigure = if stdenv.hostPlatform.isWindows then ''
    ./autogen.sh
  '' else null;


  configureFlags = [
    (lib.enableFeature shared "shared")
    (lib.enableFeature static "static")
    (lib.withFeature compressionSupport "zlib")
    (lib.withFeature sslSupport "ssl")
  ];

  passthru = {inherit compressionSupport sslSupport;};

  meta = with lib; {
    description = "An HTTP and WebDAV client library";
    homepage = "https://notroj.github.io/neon/";
    changelog = "https://github.com/notroj/${pname}/blob/${version}/NEWS";
    platforms = platforms.unix ++ platforms.windows;
    license = licenses.lgpl2;
  };
}
