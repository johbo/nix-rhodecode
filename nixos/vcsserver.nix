{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.rhodecode-vcsserver;

  configFile = pkgs.writeText "vcsserver.ini" cfg.config;
  defaultConfig = import ./vcsserver-config.nix {
    inherit cfg;
  };

in {
  imports = [
  ];

  options.services.rhodecode-vcsserver = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If enabled, an instance of the VCSServer will be started
        on the machine.
      '';
    };

    package = mkOption {
      type = types.package;
      example = literalExample "pkgs.rhodecode-vcsserver";
      default = import ../vcsserver {
        inherit pkgs;
      };
      description = ''
        The VCSServer package to use for this service.
      '';
    };

    config = mkOption {
      default = defaultConfig;
      type = types.str;
      description = ''
        Configuration file content for the VCSServer.
      '';
    };

    port = mkOption {
      description = "Port number the VCSServer should listen on.";
      default = 9900;
      type = types.int;
    };

    hostname = mkOption {
      description = "Hostname the VCSServer should bind to.";
      default = "localhost";
      type = types.string;
    };

  };

  config = mkIf cfg.enable {

    systemd.services.vcsserver = {
      description = "RhodeCode VCSServer";
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

    # TODO: Check if the vcsserver can run as a dedicated user
    # users.users.vcsserver = {
    #   isSystemUser = true;
    #   name = "vcsserver";
    #   group = "vcsserver";
    #   description = "VCSServer server user";
    # };

    # users.groups.vcsserver = {};
  };
}
