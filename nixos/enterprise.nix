{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.rhodecode-enterprise;

  configFile = pkgs.writeText "enterprise.ini" cfg.config;
  defaultConfig = import ./enterprise-config.nix {
    inherit cfg;
  };

in {
  imports = [
  ];

  options.services.rhodecode-enterprise = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If enabled, an instance of RhodeCode Enterprise will be started
        on the machine.
      '';
    };

    package = mkOption {
      type = types.package;
      example = literalExample "pkgs.rhodecode-enterprise";
      default = import ../enterprise {
        inherit pkgs;
      };
      description = ''
        The RhodeCode Enterprise package to use for this service.
      '';
    };

    config = mkOption {
      default = defaultConfig;
      type = types.str;
      description = ''
        Configuration file content for RhodeCode Enterprise.
      '';
    };

    dataDir = mkOption {
      default = "/var/lib/rhodecode-enterprise";
      type = types.str;
      description = ''
        The base directory to use for data storage.

        This directory will be created on the first startup if it
        does not yet exist.
      '';
    };

    reposDir = mkOption {
      default = "/var/lib/repositories";
      type = types.str;
      description = ''
        The directory to hold the repositories.
      '';
    };

    port = mkOption {
      description = "Port number RhodeCode Enterprise should listen on.";
      default = 5000;
      type = types.int;
    };

    hostname = mkOption {
      description = "Hostname RhodeCode Enterprise should bind to.";
      default = "0.0.0.0";
      type = types.string;
    };

    vcsserver = mkOption {
      description = "Homename and port on which the VCSServer can be reached.";
      default = "localhost:9900";
      type = types.string;
    };

    user = mkOption {
      description = "User account under which Enterprise runs.";
      default = "enterprise";
      type = types.str;
    };

    group = mkOption {
      description = "Group account under which Enterprise runs.";
      default = "enterprise";
      type = types.str;
    };

    adminUser = mkOption {
      description = "Username of the initial admin user.";
      default = "admin";
      type = types.string;
    };

    adminEmail = mkOption {
      description = "E-Mail address of the initial admin user.";
      default = "root@localhost";
      type = types.string;
    };

    initialAdminPasswordFile = mkOption {
      description = ''
        File which holds the initial admin password. Use this in combination
        with the deployment key mechanism to provide the initial admin
        password.

        A random password based on "pwgen" will be generated if no initial
        password is provided. In this case the initial password will be
        stored in the file "/root/initial-enterprise-password".
      '';
      default = "/run/keys/enterprise-initial-password";
      type = types.string;
    };

  };

  config = mkIf cfg.enable {

    systemd.services.enterprise = {
      description = "RhodeCode Enterprise";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ cfg.package ];
      script = ''
        exec gunicorn --paste ${configFile}
      '';
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
      };
    };

    systemd.services.enterprise_init = {
      wantedBy = [ "enterprise.service" ];
      partOf = [ "enterprise.service" ];
      before = [ "enterprise.service" ];
      after = [ "enterprise-initial-password-key.service" ];
      wants = [ "enterprise-initial-password-key.service" ];
      path = [ cfg.package ];
      serviceConfig.Type = "oneshot";
      script = let
        databaseInitMarker = "${cfg.dataDir}/.db-initialized";
      in ''
        # Create data directory.
        if ! test -e ${cfg.dataDir}; then
          mkdir -m 0700 -p ${cfg.dataDir}
          chown -R ${cfg.user}:${cfg.group} ${cfg.dataDir}
        fi

        # Create repositories directory.
        if ! test -e ${cfg.reposDir}; then
          mkdir -m 0700 -p ${cfg.reposDir}
          chown -R ${cfg.user}:${cfg.group} ${cfg.reposDir}
        fi

        # Set up the database
        if ! test -e ${databaseInitMarker}
        then
          initial_password_file=${cfg.initialAdminPasswordFile}
          if ! test -e $initial_password_file
          then
            initial_password_file=/root/initial-enterprise-password
            (
              umask 077
              ${pkgs.pwgen}/bin/pwgen 20 1 > $initial_password_file
            )
          fi
          ${pkgs.sudo}/bin/sudo -u enterprise paster setup-rhodecode \
              ${configFile} \
              --force-yes \
              --user=${cfg.adminUser} \
              --email=${cfg.adminEmail} \
              --password=$(cat $initial_password_file) \
              --repos=${cfg.reposDir}
          touch ${databaseInitMarker}
        else
          echo "Skipping database initialize, marker ${databaseInitMarker} found."
        fi
      '';
    };

    users.users = optionalAttrs (cfg.user == "enterprise") [{
      isSystemUser = true;
      name = "enterprise";
      group = "enterprise";
      description = "RhodeCode Enterprise server user";
    }];

    users.groups = optionalAttrs (cfg.group == "enterprise") [{
      name = "enterprise";
    }];
  };
}
