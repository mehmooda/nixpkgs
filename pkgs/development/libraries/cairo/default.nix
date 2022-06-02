{ stdenv
, lib
, pkg-config
, meson
, python3
, pixman
, lzo
, zlib
, libpng
, freetype
, glib
, libXext
, libxcb
, libXrender
, fontconfig
, x11Support ? stdenv.isLinux
, darwin
, fetchurl
, ninja
}:

stdenv.mkDerivation {
  pname = "cairo";
  version = "1.17.6";

  src = fetchurl {
    url = "https://gitlab.freedesktop.org/cairo/cairo/-/archive/1.17.6/cairo-1.17.6.tar.gz";
    sha256 = "oiJ6/BXmFmVzQcQq+YMMk3w6a/pjZhB06r7xNgDok28=";
  };

  nativeBuildInputs = [
    pkg-config
    meson
    python3
    ninja
  ];

  buildInputs = [
    pixman
    lzo
    zlib
    libpng
    freetype
    glib
    fontconfig
  ] ++ lib.optionals x11Support [
    libXext
    libxcb
    libXrender
  ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.framworks; [
    CoreFoundation
    ApplicationServices
  ]);

  mesonAutoFeatures = "auto";

  preConfigure = ''
    patchShebangs ./version.py
  '';

  meta = with lib; {
    description = "A 2D graphics library with support for multiple output devices";

    longDescription = ''
      Cairo is a 2D graphics library with support for multiple output
      devices.  Currently supported output targets include the X
      Window System, Quartz, Win32, image buffers, PostScript, PDF,
      and SVG file output.  Experimental backends include OpenGL
      (through glitz), XCB, BeOS, OS/2, and DirectFB.

      Cairo is designed to produce consistent output on all output
      media while taking advantage of display hardware acceleration
      when available (e.g., through the X Render Extension).
    '';

    homepage = "http://cairographics.org/";

    license = with licenses; [ lgpl2Plus mpl10 ];

    platforms = platforms.all;
  };
}
