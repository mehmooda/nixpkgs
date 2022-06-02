{ lib
, stdenv
, fetchFromGitHub
, meson
, ninja
, docbook-xsl-nons
, gtk-doc
, installShellFiles
, libxslt # for xsltproc
, pkg-config
, which
, libffi
, libiconv
, libintl
, libtasn1
, glib
}:

stdenv.mkDerivation rec {
  pname = "p11-kit";
  version = "0.24.1";

  src = fetchFromGitHub {
    owner = "p11-glue";
    repo = pname;
    rev = version;
    hash = "sha256-1QIMEGBZsqLYU3v5ZswD5K9VcIGLBovJlC10lBHhH7c=";
  };

  outputs = [ "out" "bin" "dev"];

  # For cross platform builds of p11-kit, libtasn1 in nativeBuildInputs
  # provides the asn1Parser binary on the hostPlatform needed for building.
  # at the same time, libtasn1 in buildInputs provides the libasn1 library
  # to link against for the target platform.
  # Hence, libtasn1 is required in both native and build inputs.
  nativeBuildInputs = [
    docbook-xsl-nons
    gtk-doc
    installShellFiles
    libtasn1
    libxslt.bin
    pkg-config
    which
    meson
    ninja
  ];

  buildInputs = [
    libffi
    libiconv
    libintl
    libtasn1
    glib
  ];

  mesonFlags = [
    "-Dsystem_config=etc"
# TODO: FIX example install output (patch p11-kit/meson.build)
#    "-Dsystem_config=/etc"
    "-Dsystemd=disabled"
    "-Dgtk_doc=true"
    "-Dbash_completion=disabled"
    "-Dtrust_paths=${lib.concatStringsSep ":" [
      "/etc/ssl/trust-source"               # p11-kit trust source
      "/etc/ssl/certs/ca-certificates.crt"  # NixOS + Debian/Ubuntu/Arch/Gentoo...
      "/etc/pki/tls/certs/ca-bundle.crt"    # Fedora/CentOS
    ]}"
  ];

  # Tests run in fakeroot for non-root users
  preCheck = ''
    if [ "$(id -u)" != "0" ]; then
      export FAKED_MODE=1
    fi
  '';

  doCheck = !stdenv.isDarwin;

#  postInstall = ''
#    installShellCompletion --bash bash-completion/{p11-kit,trust}
#  '';

  meta = with lib; {
    description = "Library for loading and sharing PKCS#11 modules";
    longDescription = ''
      Provides a way to load and enumerate PKCS#11 modules.
      Provides a standard configuration setup for installing
      PKCS#11 modules in such a way that they're discoverable.
    '';
    homepage = "https://p11-glue.github.io/p11-glue/p11-kit.html";
    changelog = [
      "https://github.com/p11-glue/p11-kit/raw/${version}/NEWS"
      "https://github.com/p11-glue/p11-kit/releases/tag/${version}"
    ];
    platforms = platforms.all;
    license = licenses.bsd3;
  };
}
