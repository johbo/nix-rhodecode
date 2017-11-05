{ pkgs ? import <nixpkgs> {}
, doCheck ? true
}:

let

  vcsserver = import ./default.nix {
    inherit
      doCheck
      pkgs;
  };

in {
  build = vcsserver;

  optSymlink = pkgs.stdenv.mkDerivation {
    name = "rhodecode-vcsserver-symlink";
    phases = "installPhase";
    installPhase = ''
      mkdir -p $out/opt/rhodecode
      ln -s ${vcsserver} $out/opt/rhodecode/vcsserver
    '';
  };
}
