{ stdenv
, lib
, fetchurl
, openssl
, nettle
, expat
, libevent
, libsodium
, protobufc
, hiredis
, python ? null
, swig
, dns-root-data
, pkg-config
, makeWrapper
, symlinkJoin
, bison
, nixosTests
  #
  # By default unbound will not be built with systemd support. Unbound is a very
  # commmon dependency. The transitive dependency closure of systemd also
  # contains unbound.
  # Since most (all?) (lib)unbound users outside of the unbound daemon usage do
  # not need the systemd integration it is likely best to just default to no
  # systemd integration.
  # For the daemon use-case, that needs to notify systemd, use `unbound-with-systemd`.
  #
, withSystemd ? false
, systemd ? null
  # optionally support DNS-over-HTTPS as a server
, withDoH ? false
, withECS ? false
, withDNSCrypt ? false
, withDNSTAP ? false
, withTFO ? false
, withRedis ? false
# Avoid .lib depending on lib.getLib openssl
# The build gets a little hacky, so in some cases we disable this approach.
, withSlimLib ? stdenv.isLinux && !stdenv.hostPlatform.isMusl && !withDNSTAP
, withPythonModule ? false
, libnghttp2
}:

stdenv.mkDerivation rec {
  pname = "unbound";
  version = "1.14.0";

  src = fetchurl {
    url = "https://nlnetlabs.nl/downloads/unbound/unbound-${version}.tar.gz";
    sha256 = "sha256-bvkcvwLVKZ6rOTKMCFc5Pee0iFov5yM93+PBJP9aicg=";
  };

  outputs = [ "out" "lib" "man" ]; # "dev" would only split ~20 kB

  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optionals withPythonModule [ swig ];

  buildInputs = [ openssl nettle expat libevent ]
    ++ lib.optionals withSystemd [ pkg-config systemd ]
    ++ lib.optionals withDoH [ libnghttp2 ]
    ++ lib.optionals withPythonModule [ python ];

  configureFlags = [
    "--with-ssl=${openssl.dev}"
    "--with-libexpat=${expat.dev}"
    "--with-libevent=${libevent.dev}"
    "--localstatedir=/var"
    "--sysconfdir=/etc"
    "--sbindir=\${out}/bin"
    "--with-rootkey-file=${dns-root-data}/root.key"
    "--enable-pie"
    "--enable-relro-now"
# Unable to build with flto on mingw due to a libtool error due to empty global_symbol_pipe
# checking command to parse x86_64-w64-mingw32-nm output from x86_64-w64-mingw32-gcc object... failed
  ] ++ lib.optional (with stdenv.hostPlatform; isStatic || isWindows) [
    "--disable-flto"
  ] ++ lib.optionals withSystemd [
    "--enable-systemd"
  ] ++ lib.optionals withPythonModule [
    "--with-pythonmodule"
  ] ++ lib.optionals withDoH [
    "--with-libnghttp2=${libnghttp2.dev}"
  ] ++ lib.optionals withECS [
    "--enable-subnet"
  ] ++ lib.optionals withDNSCrypt [
    "--enable-dnscrypt"
    "--with-libsodium=${symlinkJoin { name = "libsodium-full"; paths = [ libsodium.dev libsodium.out ]; }}"
  ] ++ lib.optionals withDNSTAP [
    "--enable-dnstap"
    "--with-protobuf-c=${protobufc}"
  ] ++ lib.optionals withTFO [
    "--enable-tfo-client"
    "--enable-tfo-server"
  ] ++ lib.optionals withRedis [
    "--enable-cachedb"
    "--with-libhiredis=${hiredis}"
  ];

  enableParallelBuilding = true;

  PROTOC_C = lib.optionalString withDNSTAP "${protobufc}/bin/protoc-c";

  # Remove references to compile-time dependencies that are included in the configure flags
  postConfigure = let
    inherit (builtins) storeDir;
  in ''
    sed -E '/CONFCMDLINE/ s;${storeDir}/[a-z0-9]{32}-;${storeDir}/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-;g' -i config.h
  '';

  checkInputs = [ bison ];

  doCheck = true;

  postPatch = lib.optionalString withPythonModule ''
    substituteInPlace Makefile.in \
      --replace "\$(DESTDIR)\$(PYTHON_SITE_PKG)" "$out/${python.sitePackages}"
  '';

  installFlags = [ "configfile=\${out}/etc/unbound/unbound.conf" ];

  postInstall = ''
    make unbound-event-install
    wrapProgram $out/bin/unbound-control-setup \
      --prefix PATH : ${lib.makeBinPath [ openssl ]}
  '' + lib.optionalString withPythonModule ''
    wrapProgram $out/bin/unbound \
      --prefix PYTHONPATH : "$out/${python.sitePackages}" \
      --argv0 $out/bin/unbound
  '';

  preFixup = lib.optionalString withSlimLib
    # Build libunbound again, but only against nettle instead of openssl.
    # This avoids gnutls.out -> unbound.lib -> lib.getLib openssl.
    ''
      configureFlags="$configureFlags --with-nettle=${nettle.dev} --with-libunbound-only"
      configurePhase
      buildPhase
      if [ -n "$doCheck" ]; then
          checkPhase
      fi
      installPhase
    ''
  # get rid of runtime dependencies on $dev outputs
  + ''substituteInPlace "$lib/lib/libunbound.la" ''
  + lib.concatMapStrings
    (pkg: lib.optionalString (pkg ? dev) " --replace '-L${pkg.dev}/lib' '-L${pkg.out}/lib' --replace '-R${pkg.dev}/lib' '-R${pkg.out}/lib'")
    (builtins.filter (p: p != null) buildInputs);

  passthru.tests = nixosTests.unbound;

  meta = with lib; {
    description = "Validating, recursive, and caching DNS resolver";
    license = licenses.bsd3;
    homepage = "https://www.unbound.net";
    maintainers = with maintainers; [ fpletz globin ];
    platforms = platforms.unix ++ platforms.windows;
  };
}
