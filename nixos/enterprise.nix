{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.rhodecode-enterprise;

  configFile =
    if isNull cfg.secretConfigFile
    then cfg.baseConfigFile
    else cfg.secretConfigFile;

  defaultConfig = import ./enterprise-config.nix {
    inherit cfg;
  };

  makeOptSymlink = import ./lib/make-opt-symlink.nix {
    inherit pkgs;
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

    baseConfigFile = mkOption {
      default = pkgs.writeText "enterprise.ini" cfg.config;
      description = ''
        Base version of "config" as a file.
      '';
      type = types.path;
    };

    secretConfigFile = mkOption {
      default = null;
      description = ''
        Path to a secret config file. If set then this config file will be used to
        run enterprise. Typically you want to refer to the attribute
        "config" via the "use = config:PATH" mechanism.

        This is intended to be used by the deployment keys of NixOPS.
      '';
      type = types.nullOr types.str;
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

    installOptSymlink = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Install the symlink into /opt/rhodecode to allow an administrator
        to easily access the CLI commands.
      '';
    };

    initializeDatabase = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Initializing the database automatically is convenient, still it is
        potentially dangerous. An example would be if you connect your shiny
        new system to an existing database.

        Turn it on when you want everything to be automatic.

        The decision if the database has to be initialized is based on a
        marker inside of the filesystem.
      '';
    };

  };

  config = mkIf cfg.enable {

    environment.systemPackages =
      pkgs.lib.optional cfg.installOptSymlink (makeOptSymlink cfg.package "enterprise");

    environment.pathsToLink = [
      "/opt/rhodecode"
    ];

    systemd.services.enterprise = {
      description = "RhodeCode Enterprise";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ cfg.package ];
      script = ''
        # Base config file: ${cfg.baseConfigFile}
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

      ''
      + (pkgs.lib.optionals cfg.initializeDatabase ''
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
      '');
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
