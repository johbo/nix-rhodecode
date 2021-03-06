{ pkgs ? (import <nixpkgs> {})
, pythonPackages ? "python27Packages"
}:

with pkgs.lib;

let _pythonPackages = pythonPackages; in
let
  pythonPackages = getAttr _pythonPackages pkgs;

  pip2nix = import ../common/pip2nix.nix {
    inherit
      pkgs
      pythonPackages;
  };

in

pkgs.stdenv.mkDerivation {
  name = "pip2nix-generated";
  buildInputs = [
    # Allows to generate python packages
    pip2nix.pip2nix
    pythonPackages.pip-tools

    # Allows to generate bower dependencies
    pkgs.nodePackages.bower2nix

    # Allows to generate node dependencies
    pkgs.nodePackages.node2nix

    # We need mysql_config to be around
    pkgs.mysql

    # We need postgresql to be around
    pkgs.postgresql

    # Curl is needed for pycurl
    pkgs.curl
  ];
}
