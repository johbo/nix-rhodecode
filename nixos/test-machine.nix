{ config, pkgs, ... }:

{
  # Makes testing easier
  boot.isContainer = true;

  imports = [
    ./enterprise.nix
    ./vcsserver.nix
  ];

  services.rhodecode-enterprise = {
    enable = true;
  };

  services.rhodecode-vcsserver = {
    enable = true;
  };

}
