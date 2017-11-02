# Nix environment for the community edition
#
# This shall be as lean as possible, just producing the Enterprise
# derivation. For advanced tweaks to pimp up the development environment we use
# "shell.nix" so that it does not have to clutter this file.

{ pkgs ? (import <nixpkgs> {})
, pythonPackages ? "python27Packages"
, pythonExternalOverrides ? self: super: {}
, doCheck ? false
}:

let

  # Evaluates to the last segment of a file system path.
  basename = path: with pkgs.lib; last (splitString "/" path);

  basePythonPackages = with builtins; if isAttrs pythonPackages
    then pythonPackages
    else getAttr pythonPackages pkgs;

  # Works with the new python-packages, still can fallback to the old
  # variant.
  basePythonPackagesUnfix = basePythonPackages.__unfix__ or (
    self: basePythonPackages.override (a: { inherit self; }));

  buildBowerComponents =
    pkgs.buildBowerComponents or
    (import ./pkgs/backport-16.03-build-bower-components.nix { inherit pkgs; });

  sources = pkgs.config.rc.sources or {};
  rhodecode-enterprise-ce-src = pkgs.fetchhg {
    url = https://code.rhodecode.com/rhodecode-enterprise-ce;
    rev = "a327c56bb684";
    sha256 = "0abckv4mwlxk32zmqf07g2lpccxfkb4bx8jhd7hqksb76rja11jf";
  };
  version = builtins.readFile "${rhodecode-enterprise-ce-src}/rhodecode/VERSION";


  nodeEnv = import ./pkgs/node-default.nix {
    inherit pkgs;
  };
  nodeDependencies = nodeEnv.shell.nodeDependencies;

  bowerComponents = buildBowerComponents {
    name = "enterprise-ce-${version}";
    generated = ./pkgs/bower-packages.nix;
    src = rhodecode-enterprise-ce-src;
  };

  pythonGeneratedPackages = import ./pkgs/python-packages.nix {
    inherit pkgs;
    inherit (pkgs) fetchurl fetchgit fetchhg;
  };

  pythonOverrides = import ./pkgs/python-packages-overrides.nix {
    inherit
      basePythonPackages
      pkgs;
  };

  pythonLocalOverrides = self: super: {
    rhodecode-enterprise-ce =
      let
        linkNodeAndBowerPackages = ''
          echo "Export RhodeCode CE path"
          export RHODECODE_CE_PATH=${rhodecode-enterprise-ce-src}
          echo "Link node packages"
          rm -fr node_modules
          mkdir node_modules
          # johbo: Linking individual packages allows us to run "npm install"
          # inside of a shell to try things out. Re-entering the shell will
          # restore a clean environment.
          ln -s ${nodeDependencies}/lib/node_modules/* node_modules/

          echo "DONE: Link node packages"

          echo "Link bower packages"
          rm -fr bower_components
          mkdir bower_components

          ln -s ${bowerComponents}/bower_components/* bower_components/
          echo "DONE: Link bower packages"
        '';
      in super.rhodecode-enterprise-ce.override (attrs: {

      inherit
        doCheck
        version;
      name = "rhodecode-enterprise-ce-${version}";
      releaseName = "RhodeCodeEnterpriseCE-${version}";
      src = rhodecode-enterprise-ce-src;
      patches = [
        # TODO: Re-check, mybe we can get there without it.
        # ./patches/reference-env-variables-in-config.patch
      ];
      dontStrip = true; # prevent strip, we don't need it.

      buildInputs =
        attrs.buildInputs ++
        (with self; [
          pkgs.nodePackages.bower
          pkgs.nodePackages.grunt-cli
          pkgs.subversion
          pytest-catchlog
          rhodecode-testdata
        ]);

      #TODO: either move this into overrides, OR use the new machanics from
      # pip2nix and requiremtn.txt file
      propagatedBuildInputs = attrs.propagatedBuildInputs ++ (with self; [
        rhodecode-tools
      ]);

      # TODO: johbo: Make a nicer way to expose the parts. Maybe
      # pkgs/default.nix?
      passthru = {
        inherit
          bowerComponents
          linkNodeAndBowerPackages
          myPythonPackagesUnfix
          pythonLocalOverrides;
        pythonPackages = self;
      };

      LC_ALL = "en_US.UTF-8";
      LOCALE_ARCHIVE =
        if pkgs.stdenv ? glibc
        then "${pkgs.glibcLocales}/lib/locale/locale-archive"
        else "";

      preCheck = ''
        export PATH="$out/bin:$PATH"
      '';

      postCheck = ''
        rm -rf $out/lib/${self.python.libPrefix}/site-packages/pytest_pylons
        rm -rf $out/lib/${self.python.libPrefix}/site-packages/rhodecode/tests
      '';

      preBuild = linkNodeAndBowerPackages + ''
        grunt
        rm -fr node_modules
      '';

      postInstall = ''
        echo "Writing meta information for rccontrol to nix-support/rccontrol"
        mkdir -p $out/nix-support/rccontrol
        cp -v rhodecode/VERSION $out/nix-support/rccontrol/version
        echo "DONE: Meta information for rccontrol written"

        # python based programs need to be wrapped
        ln -s ${self.pyramid}/bin/* $out/bin/
        ln -s ${self.gunicorn}/bin/gunicorn $out/bin/
        ln -s ${self.supervisor}/bin/supervisor* $out/bin/
        ln -s ${self.PasteScript}/bin/paster $out/bin/
        ln -s ${self.channelstream}/bin/channelstream $out/bin/

        # rhodecode-tools
        ln -s ${self.rhodecode-tools}/bin/rhodecode-* $out/bin/

        # note that condition should be restricted when adding further tools
        for file in $out/bin/*;
        do
          wrapProgram $file \
              --prefix PATH : $PATH \
              --prefix PYTHONPATH : $PYTHONPATH \
              --set PYTHONHASHSEED random
        done

        mkdir $out/etc
        cp configs/production.ini $out/etc


        # TODO: johbo: Make part of ac-tests
        if [ ! -f rhodecode/public/js/scripts.js ]; then
          echo "Missing scripts.js"
          exit 1
        fi
        if [ ! -f rhodecode/public/css/style.css ]; then
          echo "Missing style.css"
          exit 1
        fi
      '';

    });

    rhodecode-testdata = import "${rhodecode-testdata-src}/default.nix" {
    inherit
      doCheck
      pkgs
      pythonPackages;
    };

  };

  rhodecode-testdata-src = sources.rhodecode-testdata or (
    pkgs.fetchhg {
      url = "https://code.rhodecode.com/upstream/rc_testdata";
      rev = "v0.10.0";
      sha256 = "0zn9swwvx4vgw4qn8q3ri26vvzgrxn15x6xnjrysi1bwmz01qjl0";
  });

  # Apply all overrides and fix the final package set
  myPythonPackagesUnfix = with pkgs.lib;
    (extends pythonExternalOverrides
    (extends pythonLocalOverrides
    (extends pythonOverrides
    (extends pythonGeneratedPackages
             basePythonPackagesUnfix))));

  myPythonPackages = (pkgs.lib.fix myPythonPackagesUnfix);

in myPythonPackages.rhodecode-enterprise-ce
