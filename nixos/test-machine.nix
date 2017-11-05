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

        # Note: "pwgen 40 1" is your friend
        rhodecode.encrypted_values.secret = test-secret-encrypted-values
        app_instance_uuid = test-instance-uuid
        channelstream.secret = test-secret-channelstream
        beaker.session.secret = test-secret-sessions
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
    initializeDatabase = true;
  };

  services.rhodecode-vcsserver = {
    enable = true;
  };

}
