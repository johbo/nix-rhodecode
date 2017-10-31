{
  # The host system onto which the containers shall be deployed.
  # Set the value via "nixops set-args".
  host
}:

{
  rhodecode = { config, pkgs, ... }: {
    deployment.targetEnv = "container";
    deployment.container.host = host;
  };

}
