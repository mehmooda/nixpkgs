{ stdenv
, fetchurl
, meson
, ninja
, pkg-config
, gettext
, bison
, flex
, python3
, glib
, makeWrapper
, libcap
, libunwind
, darwin
, elfutils # for libdw
, bash-completion
, lib
, CoreServices
, withIntrospection ? stdenv.buildPlatform == stdenv.hostPlatform
, gobject-introspection
, windows
}:

stdenv.mkDerivation rec {
  pname = "gstreamer";
  version = "1.20.1";

  outputs = [
    "bin"
    "out"
    "dev"
    # "devdoc" # disabled until `hotdoc` is packaged in nixpkgs, see:
    # - https://github.com/NixOS/nixpkgs/pull/98767
    # - https://github.com/NixOS/nixpkgs/issues/98769#issuecomment-702296551
  ];

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/${pname}/${pname}-${version}.tar.xz";
    sha256 = "0cghi6n4nhdbajz3wqcgbh5xm94myvnqgsi9g2bz9n1s9904l2fy";
  };

  strictDeps = true;
  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    gettext
    bison
    flex
    python3
    makeWrapper
    glib
  ] ++ lib.optionals (!stdenv.hostPlatform.isWindows) [
    bash-completion

    # documentation
    # TODO add hotdoc here
  ] ++ lib.optionals stdenv.isLinux [
    libcap # for setcap binary
  ] ++ lib.optionals withIntrospection [
    gobject-introspection
  ];

  buildInputs = lib.optionals (!stdenv.hostPlatform.isWindows) [
    bash-completion
  ] ++ lib.optionals stdenv.hostPlatform.isWindows [
    windows.pthreads
  ] ++ lib.optionals stdenv.isLinux [
    libcap
    libunwind
    elfutils
  ] ++ lib.optionals withIntrospection [
    gobject-introspection
  ] ++ lib.optionals stdenv.isDarwin [
    CoreServices
  ];

  propagatedBuildInputs = [
    glib
  ];

  mesonFlags = [
    "-Ddbghelp=disabled" # not needed as we already provide libunwind and libdw, and dbghelp is a fallback to those
    "-Dexamples=disabled" # requires many dependencies and probably not useful for our users
    "-Ddoc=disabled" # `hotdoc` not packaged in nixpkgs as of writing
    "-Dintrospection=${if withIntrospection then "enabled" else "disabled"}"
  ] ++ lib.optionals (stdenv.hostPlatform.isWindows) [
    "-Dbash-completion=disabled"
  ] ++ lib.optionals (!stdenv.hostPlatform.isLinux) [
    # darwin.libunwind doesn't have pkg-config definitions so meson doesn't detect it.
    "-Dlibunwind=disabled"
    "-Dlibdw=disabled"
  ];

  postPatch = ''
    patchShebangs \
      gst/parse/get_flex_version.py \
      gst/parse/gen_grammar.py.in \
      gst/parse/gen_lex.py.in \
      libs/gst/helpers/ptp_helper_post_install.sh \
      scripts/extract-release-date-from-doap-file.py
  '';

  postInstall = ''
    for prog in "$bin/bin/"'' +
    # TODO: Make wrapProgram smarter.
    #       Also make is work on windows
    #       This is needed so that dll get moved correctly afterwards
    (if stdenv.hostPlatform.isWindows then ''*.exe'' else ''*'') +
    ''; do
        # We can't use --suffix here due to quoting so we craft the export command by hand
        wrapProgram "$prog" --run 'export GST_PLUGIN_SYSTEM_PATH_1_0=$GST_PLUGIN_SYSTEM_PATH_1_0''${GST_PLUGIN_SYSTEM_PATH_1_0:+:}$(unset _tmp; for profile in $NIX_PROFILES; do _tmp="$profile/lib/gstreamer-1.0''${_tmp:+:}$_tmp"; done; printf '%s' "$_tmp")'
    done
  '';

  preFixup = ''
    moveToOutput "share/bash-completion" "$bin"
  '';

  setupHook = ./setup-hook.sh;

  meta = with lib ;{
    description = "Open source multimedia framework";
    homepage = "https://gstreamer.freedesktop.org";
    license = licenses.lgpl2Plus;
    platforms = platforms.unix ++ platforms.windows;
    maintainers = with maintainers; [ ttuegel matthewbauer ];
  };
}
