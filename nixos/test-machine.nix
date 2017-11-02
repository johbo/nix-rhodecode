{ config, pkgs, ... }:

{
  imports = [
    ./enterprise.nix
    ./vcsserver.nix
  ];

  deployment.keys = let
    cfg = config.services.rhodecode-enterprise;
  in {
    enterprise-initial-password = {
      text = "secret";
    };
    enterprise-secret-config = {
      text = ''
        [server:main]
        use = config:${cfg.baseConfigFile}

        [app:main]
        use = config:${cfg.baseConfigFile}
        sqlalchemy.db1.url = sqlite:///${cfg.dataDir}/rhodecode.db?timeout=30

        # TODO: Set the following
        # rhodecode.encrypted_values.secret =
        app_instance_uuid = rc-pre-prod-test-johannes
        channelstream.secret = secret
        beaker.session.secret = peoen32w9x8en
      '';
      user = "enterprise";
      group = "enterprise";
    };
  };

  users.groups.keys.members = [
    "enterprise"
  ];

  networking.firewall.allowedTCPPorts = [
    5000
  ];

  services.rhodecode-enterprise = {
    enable = true;
    secretConfigFile = "/run/keys/enterprise-secret-config";
  };

  services.rhodecode-vcsserver = {
    enable = true;
  };

}
