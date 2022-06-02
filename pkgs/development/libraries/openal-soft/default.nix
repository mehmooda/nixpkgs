{ lib, stdenv, fetchFromGitHub, cmake, pkg-config
, notDarows ? !(stdenv.isDarwin || stdenv.hostPlatform.isWindows)
, alsaSupport ? notDarows, alsa-lib
, dbusSupport ? notDarows, dbus
, pipewireSupport ? notDarows, pipewire
, pulseSupport ? notDarows, libpulseaudio
, CoreServices, AudioUnit, AudioToolbox
}:

stdenv.mkDerivation rec {
  pname = "openal-soft";
  version = "1.22.0";

  src = fetchFromGitHub {
    owner = "kcat";
    repo = "openal-soft";
    rev = version;
    sha256 = "sha256-Y2KhPkwtG6tBzUhSqwV2DVnOjZwxPihidLKahjaIvyU=";
  };

  # this will make it find its own data files (e.g. HRTF profiles)
  # without any other configuration
  patches = [ ./search-out.patch ];
  postPatch = ''
    substituteInPlace core/helpers.cpp \
      --replace "@OUT@" $out
  '';

  strictDeps = true;

  nativeBuildInputs = [ cmake pkg-config ];

  buildInputs = lib.optional (stdenv.buildPlatform != stdenv.hostPlatform) stdenv.cc.libc
    ++ lib.optional alsaSupport alsa-lib
    ++ lib.optional dbusSupport dbus
    ++ lib.optional pipewireSupport pipewire
    ++ lib.optional pulseSupport libpulseaudio
    ++ lib.optionals stdenv.isDarwin [ CoreServices AudioUnit AudioToolbox ];

  cmakeFlags = [
    # Automatically links dependencies without having to rely on dlopen, thus
    # removes the need for NIX_LDFLAGS.
    "-DALSOFT_DLOPEN=OFF"
  ];


  # openal.pc is broken for some reason
  postFixup = if stdenv.hostPlatform.isWindows then ''
    sed -e 's,''${exec_prefix}/,,' -e 's,''${prefix}/,,' -i $out/lib/pkgconfig/openal.pc
  '' else null;

  meta = with lib; {
    description = "OpenAL alternative";
    homepage = "https://kcat.strangesoft.net/openal.html";
    license = licenses.lgpl2;
    maintainers = with maintainers; [ftrvxmtrx];
    platforms = platforms.unix ++ platforms.windows;
  };
}
