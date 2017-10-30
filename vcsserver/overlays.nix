self: super: {
  # bump GIT version
  git = super.lib.overrideDerivation super.git (oldAttrs: {
    name = "git-2.13.5";
    src = self.fetchurl {
      url = "https://www.kernel.org/pub/software/scm/git/git-2.13.5.tar.xz";
      sha256 = "18fi18103n7grshm4ffb0fwsnvbl48sbqy5gqx528vf8maff5j91";
    };

    patches = [
      ./pkgs/git_patches/docbook2texi.patch
      ./pkgs/git_patches/symlinks-in-bin.patch
      ./pkgs/git_patches/git-sh-i18n.patch
      ./pkgs/git_patches/ssh-path.patch
    ];

  });

  # Override subversion derivation to
  #  - activate python bindings
  subversion =
  let
    subversionWithPython = super.subversion.override {
      httpSupport = true;
      pythonBindings = true;
      python = self.python27Packages.python;
    };
  in
    super.lib.overrideDerivation subversionWithPython (oldAttrs: {
      name = "subversion-1.9.7";
      src = self.fetchurl {
        url = "https://www.apache.org/dist/subversion/subversion-1.9.7.tar.gz";
        sha256 = "0g3cs2h008z8ymgkhbk54jp87bjh7y049rn42igj881yi2f20an7";
      };
  });

}
