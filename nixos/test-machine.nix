{ config, pkgs, ... }:

{
  # Makes testing easier
  boot.isContainer = true;

  imports = [
    ./enterprise.nix
    ./vcsserver.nix
  ];

  networking.firewall.allowedTCPPorts = [
    5000
  ];

  services.rhodecode-enterprise = {
    enable = true;
  };

  services.rhodecode-vcsserver = {
    enable = true;
  };

}
