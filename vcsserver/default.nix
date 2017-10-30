# Nix environment for the community edition
#
# This shall be as lean as possible, just producing the rhodecode-vcsserver
# derivation. For advanced tweaks to pimp up the development environment we use
# "shell.nix" so that it does not have to clutter this file.

{ pkgs ? (import <nixpkgs> {})
, pythonPackages ? "python27Packages"
, pythonExternalOverrides ? self: super: {}
, doCheck ? true
}:

let pkgs_ = pkgs; in

let

  # TODO: Currently we ignore the passed in pkgs, instead we should use it
  # somehow as a base and apply overlays to it.
  pkgs = import <nixpkgs> {
    overlays = [
      (import ./overlays.nix)
    ];
  };

  inherit (pkgs.lib) fix extends;
  basePythonPackages = with builtins; if isAttrs pythonPackages
    then pythonPackages
    else getAttr pythonPackages pkgs;

  # Works with the new python-packages, still can fallback to the old
  # variant.
  basePythonPackagesUnfix = basePythonPackages.__unfix__ or (
    self: basePythonPackages.override (a: { inherit self; }));

  elem = builtins.elem;
  basename = path: with pkgs.lib; last (splitString "/" path);
  startsWith = prefix: full: let
    actualPrefix = builtins.substring 0 (builtins.stringLength prefix) full;
  in actualPrefix == prefix;

  rhodecode-vcsserver-src = pkgs.fetchhg {
    url = https://code.rhodecode.com/rhodecode-vcsserver;
    rev = "6ed1dd13d98f";
    sha256 = "138s58k013nyr50b3xfp3x3pdqrnmq2s5kli6bgn3kx94pl9z3l6";
  };

  # TODO: Move
  rhodecode-enterprise-src = pkgs.fetchhg {
    url = https://code.rhodecode.com/rhodecode-enterprise-ce;
    rev = "a327c56bb684";
    sha256 = "0abckv4mwlxk32zmqf07g2lpccxfkb4bx8jhd7hqksb76rja11jf";
  };

  pythonGeneratedPackages = import ./pkgs/python-packages.nix {
    inherit pkgs;
    inherit (pkgs) fetchurl fetchgit fetchhg;
  };

  pythonOverrides = import ./pkgs/python-packages-overrides.nix {
    inherit basePythonPackages pkgs;
  };

  version = builtins.readFile "${rhodecode-vcsserver-src}/vcsserver/VERSION";

  pythonLocalOverrides = self: super: {
    rhodecode-vcsserver = super.rhodecode-vcsserver.override (attrs: {
      inherit doCheck version;

      name = "rhodecode-vcsserver-${version}";
      releaseName = "RhodeCodeVCSServer-${version}";
      src = rhodecode-vcsserver-src;
      dontStrip = true; # prevent strip, we don't need it.

      propagatedBuildInputs = attrs.propagatedBuildInputs ++ ([
        pkgs.git
        pkgs.subversion
      ]);

      patches = [
        ./pkgs/vcsserver-requirements.patch
        ./pkgs/vcsserver-requirements-mercurial.patch
      ];

      # TODO: johbo: Make a nicer way to expose the parts. Maybe
      # pkgs/default.nix?
      passthru = {
        pythonPackages = self;
      };

      # Add VCSServer bin directory to path so that tests can find 'vcsserver'.
      preCheck = ''
        export PATH="$out/bin:$PATH"
      '';

      # put custom attrs here
      checkPhase = ''
        runHook preCheck
        PYTHONHASHSEED=random py.test -p no:sugar -vv --cov-config=.coveragerc --cov=vcsserver --cov-report=term-missing vcsserver
        runHook postCheck
      '';

      postInstall = ''
        echo "Writing meta information for rccontrol to nix-support/rccontrol"
        mkdir -p $out/nix-support/rccontrol
        cp -v vcsserver/VERSION $out/nix-support/rccontrol/version
        echo "DONE: Meta information for rccontrol written"

        # python based programs need to be wrapped
        mkdir -p $out/bin
        ln -s ${self.pyramid}/bin/* $out/bin/
        ln -s ${self.gunicorn}/bin/gunicorn $out/bin/

        # Symlink version control utilities
        #
        # We ensure that always the correct version is available as a symlink.
        # So that users calling them via the profile path will always use the
        # correct version.
        ln -s ${pkgs.git}/bin/git $out/bin
        ln -s ${self.mercurial}/bin/hg $out/bin
        ln -s ${pkgs.subversion}/bin/svn* $out/bin

        for file in $out/bin/*;
        do
          wrapProgram $file \
            --set PATH $PATH \
            --set PYTHONPATH $PYTHONPATH \
            --set PYTHONHASHSEED random
        done

      '';

    });
  };

  # Apply all overrides and fix the final package set
  myPythonPackages =
    (fix
    (extends pythonExternalOverrides
    (extends pythonLocalOverrides
    (extends pythonOverrides
    (extends pythonGeneratedPackages
             basePythonPackagesUnfix)))));

in myPythonPackages.rhodecode-vcsserver
