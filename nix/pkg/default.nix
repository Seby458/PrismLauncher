{
  lib,
  stdenv,
  canonicalize-jars-hook,
  cmake,
  cmark,
  Cocoa,
  ninja,
  jdk17,
  zlib,
  qtbase,
  qtnetworkauth,
  quazip,
  extra-cmake-modules,
  tomlplusplus,
  ghc_filesystem,
  gamemode,
  msaClientID ? null,
  gamemodeSupport ? stdenv.isLinux,
  version,
  libnbtplusplus,
}:
assert lib.assertMsg (stdenv.isLinux || !gamemodeSupport) "gamemodeSupport is only available on Linux";
  stdenv.mkDerivation rec {
    pname = "prismlauncher-unwrapped";
    inherit version;

    src = lib.fileset.toSource {
      root = ../../.;
      fileset = lib.fileset.unions (map (fileName: ../../${fileName}) [
        "buildconfig"
        "cmake"
        "launcher"
        "libraries"
        "program_info"
        "tests"
        "COPYING.md"
        "CMakeLists.txt"
      ]);
    };

    nativeBuildInputs = [extra-cmake-modules cmake jdk17 ninja canonicalize-jars-hook];
    buildInputs =
      [
        qtbase
        qtnetworkauth
        zlib
        quazip
        ghc_filesystem
        tomlplusplus
        cmark
      ]
      ++ lib.optional gamemodeSupport gamemode
      ++ lib.optionals stdenv.isDarwin [Cocoa];

    hardeningEnable = lib.optionals stdenv.isLinux ["pie"];

    cmakeFlags =
      [
        "-DLauncher_BUILD_PLATFORM=nixpkgs"
      ]
      ++ lib.optionals (msaClientID != null) ["-DLauncher_MSA_CLIENT_ID=${msaClientID}"]
      ++ lib.optionals (lib.versionOlder qtbase.version "6") ["-DLauncher_QT_VERSION_MAJOR=5"]
      ++ lib.optionals stdenv.isDarwin ["-DINSTALL_BUNDLE=nodeps" "-DMACOSX_SPARKLE_UPDATE_FEED_URL=''"];

    postUnpack = ''
      rm -rf source/libraries/libnbtplusplus
      ln -s ${libnbtplusplus} source/libraries/libnbtplusplus
    '';

    dontWrapQtApps = true;

    meta = with lib; {
      mainProgram = "prismlauncher";
      homepage = "https://prismlauncher.org/";
      description = "A free, open source launcher for Minecraft";
      longDescription = ''
        Allows you to have multiple, separate instances of Minecraft (each with
        their own mods, texture packs, saves, etc) and helps you manage them and
        their associated options with a simple interface.
      '';
      platforms = with platforms; linux ++ darwin;
      changelog = "https://github.com/PrismLauncher/PrismLauncher/releases/tag/${version}";
      license = licenses.gpl3Only;
      maintainers = with maintainers; [minion3665 Scrumplex getchoo];
    };
  }
