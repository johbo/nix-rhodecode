{ config, pkgs, ... }:

{
  imports = [
    ./enterprise.nix
    ./vcsserver.nix
  ];

  deployment.keys = {
    enterprise-initial-password = {
      text = "secret";
    };
  };

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
