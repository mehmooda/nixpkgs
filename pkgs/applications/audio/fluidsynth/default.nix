{ stdenv, lib, fetchFromGitHub, pkgsBuildBuild, pkg-config, cmake
, alsa-lib, glib, libjack2, libsndfile, libpulseaudio
, AudioUnit, CoreAudio, CoreMIDI, CoreServices
}:

stdenv.mkDerivation rec {
  pname = "fluidsynth";
  version = "2.2.5";

  src = fetchFromGitHub {
    owner = "FluidSynth";
    repo = "fluidsynth";
    rev = "v${version}";
    sha256 = "sha256-aR8TLxl6OziP+DMSNro0DB/UtvzXDeDYQ3o/iy70XD4=";
  };

  postPatch = ''
    ${pkgsBuildBuild.stdenv.cc}/bin/cc make_tables.c gen_conv.c gen_rvoice_dsp.c -o gentables
  '';

  nativeBuildInputs = [ pkg-config cmake ];

  buildInputs = [ glib libsndfile  ]
    ++ lib.optionals stdenv.hostPlatform.isUnix [libjack2 ]
    ++ lib.optionals stdenv.isLinux [ alsa-lib libpulseaudio ]
    ++ lib.optionals stdenv.isDarwin [ AudioUnit CoreAudio CoreMIDI CoreServices ];

  cmakeFlags = [ "-Denable-framework=off" ];

  meta = with lib; {
    description = "Real-time software synthesizer based on the SoundFont 2 specifications";
    homepage    = "https://www.fluidsynth.org";
    license     = licenses.lgpl21Plus;
    maintainers = with maintainers; [ goibhniu lovek323 ];
    platforms   = platforms.unix ++ platforms.windows;
  };
}
