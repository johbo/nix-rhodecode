{ pkgs ? import <nixpkgs> {}
, doCheck ? false
}:

let

  vcsserver = import ./default.nix {
    inherit pkgs doCheck;
  };

  vcs-pythonPackages = vcsserver.pythonPackages;

in vcsserver.override (attrs: {

  # Avoid that we dump any sources into the store when entering the shell and
  # make development a little bit more convenient.
  src = null;

  buildInputs =
    attrs.buildInputs ++
    (with vcs-pythonPackages; [
      ipdb
    ]);

  # Somewhat snappier setup of the development environment
  # TODO: think of supporting a stable path again, so that multiple shells
  #       can share it.
  postShellHook = ''
    # Set locale
    export LC_ALL="en_US.UTF-8"

    # Custom prompt to distinguish from other dev envs.
    export PS1="\n\[\033[1;32m\][VCS-shell:\w]$\[\033[0m\] "

    tmp_path=$(mktemp -d)
    export PATH="$tmp_path/bin:$PATH"
    export PYTHONPATH="$tmp_path/${vcs-pythonPackages.python.sitePackages}:$PYTHONPATH"
    mkdir -p $tmp_path/${vcs-pythonPackages.python.sitePackages}
    python setup.py develop --prefix $tmp_path --allow-hosts ""
  '';
})
