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

    dataDirectory = mkOption {
      default = "/var/lib/rhodecode-enterprise";
      type = types.str;
      description = ''
        The base directory to use for data storage.

        This directory will be created on the first startup if it
        does not yet exist.
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
        User = "enterprise";
        Group = "enterprise";
      };
    };

    users.users.enterprise = {
      isSystemUser = true;
      name = "enterprise";
      group = "enterprise";
      description = "RhodeCode Enterprise server user";
    };

    users.groups.enterprise = {};
  };
}
