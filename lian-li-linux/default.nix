{ lib
, fetchFromGitHub
, pkg-config
, cmake
, nasm
, libusb1
, ffmpeg
, fontconfig
, libGL
, libxkbcommon
, wayland
, wayland-protocols
, libx11
, libxcursor
, libxrandr
, libxi
, libinput
, libdrm
, libjpeg_turbo
, evdi
, addDriverRunpath
, patchelf
, makeWrapper
, stdenv
}:

let
  rustPlatform = (import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.tar.gz";
    sha256 = "1vkilgbwjpyhjjyx1i75wcinqxgk5smy1gmqyvl41v262awl6jlv";
  }) { system = stdenv.hostPlatform.system; }).rustPlatform;
in

rustPlatform.buildRustPackage rec {
  pname = "lian-li-linux";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "sgtaziz";
    repo = "lian-li-linux";
    rev = "d262007c9bfbe87ae7c9d390d68ec74e5deb4d0a";
    fetchSubmodules = true;
    hash = "sha256-BqbrWtYcTAG5VyHMnban5qARr9Qdinr1EN5WeBBoZqQ=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "slint-1.16.0" = "sha256-aVonGMjp2xKsLKR9MQN6gSvY3PpmZHb58GQaPmZ6EMU=";
    };
  };

  nativeBuildInputs = [
    pkg-config
    cmake
    nasm
    rustPlatform.bindgenHook
    addDriverRunpath
    patchelf
    makeWrapper
  ];

  buildInputs = [
    libusb1
    ffmpeg
    fontconfig
    libGL
    libxkbcommon
    wayland
    wayland-protocols
    libx11
    libxcursor
    libxrandr
    libxi
    libinput
    libdrm
    libjpeg_turbo
    evdi
  ];

  env.SLINT_NO_QT = "1";

  postInstall = ''
    install -Dm644 packaging/desktop/com.sgtaziz.lianlilinux.desktop \
      $out/share/applications/com.sgtaziz.lianlilinux.desktop
    install -Dm644 assets/icons/32x32.png \
      $out/share/icons/hicolor/32x32/apps/com.sgtaziz.lianlilinux.png
    install -Dm644 assets/icons/128x128.png \
      $out/share/icons/hicolor/128x128/apps/com.sgtaziz.lianlilinux.png
    install -Dm644 "assets/icons/128x128@2x.png" \
      $out/share/icons/hicolor/256x256/apps/com.sgtaziz.lianlilinux.png
    install -Dm644 assets/icons/icon.svg \
      $out/share/icons/hicolor/scalable/apps/com.sgtaziz.lianlilinux.svg
  '';

  postFixup = ''
    addDriverRunpath $out/bin/lianli-gui

    mkdir -p $out/lib
    ln -s ${evdi}/lib/libevdi.so $out/lib/libevdi.so.1
    patchelf --add-rpath $out/lib $out/bin/lianli-daemon

    patchelf --add-rpath ${lib.makeLibraryPath [
      libxkbcommon libGL wayland libx11 libxcursor
      libxrandr libxi libinput libdrm
    ]} $out/bin/lianli-gui

    for bin in $out/bin/*; do
      wrapProgram "$bin" --prefix PATH : ${lib.makeBinPath [ ffmpeg ]}
    done
  '';

  doCheck = false;

  meta = {
    description = "Open-source Linux replacement for L-Connect 3 (fan control, RGB, LCD streaming for Lian Li devices)";
    homepage = "https://github.com/sgtaziz/lian-li-linux";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "lianli-gui";
  };
}
