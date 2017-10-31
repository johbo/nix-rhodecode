{ config, pkgs, ... }:

{
  # Makes testing easier
  boot.isContainer = true;

  imports = [
    ./vcsserver.nix
  ];

  services.rhodecode-vcsserver = {
    enable = true;
  };

}
