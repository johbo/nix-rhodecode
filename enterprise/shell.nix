{ pkgs ? (import <nixpkgs> {})
, pythonPackages ? "python27Packages"
, doCheck ? true
, sourcesOverrides ? {}
, doDevelopInstall ? true
}:

let
  # Get sources from config and update them with overrides.
  sources = (pkgs.config.rc.sources or {}) // sourcesOverrides;

  enterprise-ce = import ./default.nix {
    inherit pkgs pythonPackages doCheck;
  };

  ce-pythonPackages = enterprise-ce.pythonPackages;

  # This method looks up a path from `pkgs.config.rc.sources` and returns a
  # shell script which does a `python setup.py develop` installation of it. If
  # no path is found it will return an empty string.
  optionalDevelopInstall = attributeName:
    let
      path = pkgs.lib.attrByPath [attributeName] null sources;
      doIt = doDevelopInstall && path != null;
    in
      pkgs.lib.optionalString doIt (
      builtins.trace "Develop install of ${attributeName} from ${path}" ''
        echo "Develop install of '${attributeName}' from '${path}' [BEGIN]"
        pushd ${path}
        python setup.py develop --prefix $tmp_path --allow-hosts ""
        popd
        echo "Develop install of '${attributeName}' from '${path}' [DONE]"
      '');

  # This method looks up a path from `pkgs.config.rc.sources` and imports the
  # default.nix file if it exists. It returns the list of build inputs. If no
  # path is found it will return an empty list.
  optionalDevelopInstallBuildInputs = attributeName:
    let
      path = pkgs.lib.attrByPath [attributeName] null sources;
      nixFile = "${path}/default.nix";
      doIt = doDevelopInstall && path != null && pkgs.lib.pathExists "${nixFile}";
      derivate = import "${nixFile}" {
        inherit doCheck pkgs pythonPackages;
      };
    in
      pkgs.lib.lists.optionals doIt derivate.propagatedNativeBuildInputs;

  developInstalls = [ "rhodecode-vcsserver" ];

in enterprise-ce.override (attrs: {
  # Avoid that we dump any sources into the store when entering the shell and
  # make development a little bit more convenient.
  src = null;

  buildInputs =
    attrs.buildInputs ++
    pkgs.lib.lists.concatMap optionalDevelopInstallBuildInputs developInstalls ++
    (with ce-pythonPackages; [
      bumpversion
      invoke
      ipdb
    ]);

  shellHook = enterprise-ce.linkNodeAndBowerPackages + ''
    # Custom prompt to distinguish from other dev envs.
    export PS1="\n\[\033[1;32m\][CE-shell:\w]$\[\033[0m\] "

    # Setup a temporary directory.
    tmp_path=$(mktemp -d)
    export PATH="$tmp_path/bin:$PATH"
    export PYTHONPATH="$tmp_path/${ce-pythonPackages.python.sitePackages}:$PYTHONPATH"
    mkdir -p $tmp_path/${ce-pythonPackages.python.sitePackages}

    # Develop installations
    python setup.py develop --prefix $tmp_path --allow-hosts ""
    echo "Additional develop installs"
  '' + pkgs.lib.strings.concatMapStrings optionalDevelopInstall developInstalls;

})
