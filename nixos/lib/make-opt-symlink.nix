{ pkgs
}:

package: name: pkgs.stdenv.mkDerivation {
  name = "rhodecode-${name}-symlink";
  phases = "installPhase";
  installPhase = ''
    mkdir -p $out/opt/rhodecode
    ln -s ${package} $out/opt/rhodecode/${name}
  '';
}
