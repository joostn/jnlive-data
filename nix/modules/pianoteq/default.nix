#https://github.com/qhga/nix-pianoteq7/blob/main/flake.nix
{ pkgs, ... }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "pianoteq";
  version = "9.0.3";

  icon = fetchurl {
    name = "pianoteq_icon_128";
    url = "https://www.pianoteq.com/images/logo/pianoteq_icon_128.png";
    sha256 = "sha256-lO5kz2aIpJ108L9w2BHnRmq6wQP+6rF0lqifgor8xtM=";
  };

  src = requireFile {
    name = "pianoteq_setup_v903.tar.xz";
    sha256 = "f9a52efc60d349535d91174fb2af953efc3658be32262cda3ff1123229c4fd9e";
    url = "https://www.modartt.com/pianoteq";
    message = ''
      This file is commercial and cannot be downloaded automatically.
      Please download pianoteq_setup_v903.tar.xz from your Modartt user account
      and add it to the nix store using:

      nix-store --add-fixed sha256 pianoteq_setup_v903.tar.xz
    '';
  };

  desktopItems = [
    (makeDesktopItem {
      name = "pianoteq9";
      desktopName = "Pianoteq 9";
      exec = "pianoteq9";
      icon = "pianoteq_icon_128";
    })
  ];

  nativeBuildInputs = [
    xz
    gnutar
    copyDesktopItems
  ];

  libPath = lib.makeLibraryPath [
    alsa-lib
    freetype
    xorg.libX11
    xorg.libXext
    stdenv.cc.cc.lib
    libjack2
    lv2
    libGL
    fontconfig
  ];

  unpackCmd = "tar -xJf ${src}";

  # `runHook postInstall` is mandatory otherwise postInstall won't run
  installPhase = ''
    install -Dm 755 x86-64bit/Pianoteq\ 9 $out/bin/pianoteq9
    install -Dm 755 x86-64bit/Pianoteq\ 9.lv2/Pianoteq_9.so \
                    $out/lib/lv2/Pianoteq\ 9.lv2/Pianoteq_9.so
    patchelf --set-interpreter "$(< $NIX_CC/nix-support/dynamic-linker)" \
              --set-rpath $libPath "$out/bin/pianoteq9"
    cd x86-64bit/Pianoteq\ 9.lv2/
    for i in *.ttl; do
        install -D "$i" "$out/lib/lv2/Pianoteq 9.lv2/$i"
    done
    runHook postInstall
  '';

  # This also works instead of the following
  # makeWrapper $out/bin/pianoteq7 $out/bin/pianoteq7_wrapped --prefix LD_LIBRARY_PATH : "$libPath"
  fixupPhase = '':'';

  # Runs copyDesktopItems hook.
  # Alternatively call copyDesktopItems manually in installPhase/fixupPhase
  postInstall = ''
    install -Dm 444 ${icon} $out/share/icons/hicolor/128x128/apps/pianoteq_icon_128.png
  '';

  meta = {
    homepage = "https://www.modartt.com/";
    description = "Pianoteq is a virtual instrument which in contrast to other virtual instruments is physically modelled and thus can simulate the playability and complex behaviour of real acoustic instruments. Because there are no samples, the file size is just a tiny fraction of that required by other virtual instruments.";
    platforms = lib.platforms.linux;
  };
}
