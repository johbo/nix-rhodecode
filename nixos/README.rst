
===============
 NixOS modules
===============

This folder contains modules to run the needed components in a NixOS_ system or
a container_.


Testing via `nix-build`
=======================

The following command allows to build the test machine configuration:

.. code:: shell

   nix-build --argstr system x86_64-linux \
       '<nixpkgs/nixos>' \
       -A system \
       -I nixos-config=./test-machine.nix \
       --show-trace



Testing via NixOPS
==================

A small example network is included, which can be used to quickly deploy the
service into a container via NixOPS. This depends on Nix and NixOPS being
correctly set up.

Create the deployment and set the argument `host` to an existing NixOS machine
which shall serve as the target for the container:

.. code:: shell

   nixops create -d rhodecode test-nixops.nix test-nixops-container.nix
   nixops set-args -d rhodecode --argstr host nixvm

Now the container can be deployed as follows:

.. code:: shell

   nixops deploy -d rhodecode


Verify if the VCSServer is running:

.. code:: shell

    $ nixops ssh -d rhodecode rhodecode
    Last login: Tue Oct 31 20:30:29 2017 from 10.233.3.1

    [root@rhodecode:~]# curl http://localhost:9900/status
    {"vcsserver_version": "4.10.0", "status": "OK"}



.. Links


.. _NixOS: https://nixos.org/nixos

.. _container: https://nixos.org/nixos/manual/index.html#ch-containers
