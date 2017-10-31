{ config, pkgs, ... }:

{
  # Makes testing easier
  boot.isContainer = true;

  imports = [
    ./vcsserver.nix
  ];

}
