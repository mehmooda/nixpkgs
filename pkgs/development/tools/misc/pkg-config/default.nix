{ lib, stdenv, fetchurl, libiconv, vanilla ? false,
# Cross-compiling
glib, pkg-config }:

with lib;

stdenv.mkDerivation rec {
  pname = "pkg-config";
  version = "0.29.2";

  src = fetchurl {
    url = "https://pkg-config.freedesktop.org/releases/${pname}-${version}.tar.gz";
    sha256 = "14fmwzki1rlz8bs2p810lk6jqdxsk966d8drgsjmi54cd00rrikg";
  };

  outputs = [ "out" "man" "doc" ];
  strictDeps = true;

  # Process Requires.private properly, see
  # http://bugs.freedesktop.org/show_bug.cgi?id=4738, migrated to
  # https://gitlab.freedesktop.org/pkg-config/pkg-config/issues/28
  patches = optional (!vanilla) ./requires-private.patch
    ++ optional stdenv.isCygwin ./2.36.3-not-win32.patch;

  # These three tests fail due to a (desired) behavior change from our ./requires-private.patch
  postPatch = if vanilla then null else ''
    rm -f check/check-requires-private check/check-gtk check/missing
  '';

  nativeBuildInputs = optional (stdenv.buildPlatform != stdenv.hostPlatform) pkg-config;


  buildInputs = optional (stdenv.isCygwin || stdenv.isDarwin || stdenv.isSunOS) libiconv
       ++ optional (stdenv.buildPlatform != stdenv.hostPlatform) glib;

  configureFlags = optional (stdenv.buildPlatform == stdenv.hostPlatform) "--with-internal-glib"
    ++ optional (stdenv.isSunOS) [ "--with-libiconv=gnu" "--with-system-library-path" "--with-system-include-path" "CFLAGS=-DENABLE_NLS" ]
       # Can't run these tests while cross-compiling
    ++ optional (stdenv.hostPlatform != stdenv.buildPlatform)
       [ "glib_cv_stack_grows=no"
         "glib_cv_uscore=no"
         "ac_cv_func_posix_getpwuid_r=yes"
         "ac_cv_func_posix_getgrgid_r=yes"
       ];

  enableParallelBuilding = true;
  doCheck = true;

  postInstall = ''rm -f "$out"/bin/*-pkg-config''; # clean the duplicate file

  meta = {
    description = "A tool that allows packages to find out information about other packages";
    homepage = "http://pkg-config.freedesktop.org/wiki/";
    platforms = platforms.all;
    license = licenses.gpl2Plus;
  };
}
