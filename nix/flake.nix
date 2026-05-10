{
  description = "jnlive configuration with plugins";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    jnlive.url = "github:joostn/jnlive";
  };

  outputs = { self, nixpkgs, jnlive }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          pianoteq = pkgs.callPackage ./modules/pianoteq/default.nix { };

          jnlive-app = jnlive.packages.${system}.default;

          # Collect all LV2 plugins into one directory
          lv2-plugins = pkgs.runCommand "jnlive-lv2-plugins" { } ''
            mkdir -p $out
            ln -s "${pianoteq}/lib/lv2/Pianoteq 9.lv2" $out/
            ln -s "${pkgs.surge-XT}/lib/lv2/Surge XT.lv2" $out/
            ln -s "${pkgs.distrho-ports}/lib/lv2/Dexed.lv2" $out/
            ln -s "${pkgs.distrho-ports}/lib/lv2/TAL-Reverb-2.lv2" $out/
            ln -s "${pkgs.setbfree}/lib/lv2/b_synth" $out/
            ln -s "${pkgs.fluida-lv2}/lib/lv2/Fluida.lv2" $out/
            ln -s "${pkgs.sfizz-ui}/lib/lv2/sfizz.lv2" $out/
            ln -s "${pkgs.yoshimi}/lib/lv2/yoshimi.lv2" $out/
            ln -s "${pkgs.odin2}/lib/lv2/Odin2.lv2" $out/
          '';

          jnlive-with-plugins = pkgs.stdenv.mkDerivation {
            pname = "jnlive-with-plugins";
            version = "0.1.2";

            phases = [ "installPhase" ];

            installPhase = ''
              mkdir -p $out/share/applications
              cat <<EOF > $out/share/applications/jnlive-withplugins.desktop
              [Desktop Entry]
              Name=jnlive
              Version=0.1.2
              GenericName=LV2 Live Player (with plugis)
              Comment=Software for live playing LV2 instrument plugins
              Icon=audio-x-generic
              Exec=env GDK_BACKEND=x11 FLTK_SCALING_FACTOR=2.0 LV2_PATH=${lv2-plugins}:${pkgs.infamousPlugins}/lib/lv2 "${jnlive-app}/bin/jnlive" %F
              Terminal=true
              Type=Application
              Categories=AudioVideo;Audio;Midi;Utility;
              EOF
            '';
          };
        in
        {
          default = jnlive-with-plugins;
          jnlive-with-plugins = jnlive-with-plugins;
          pianoteq = pianoteq;
          lv2-plugins = lv2-plugins;
        }
      );
    };
}
