
===============
 NixOS modules
===============

This folder contains modules to run the needed components in a NixOS_ system or
a container_.


Testing
=======

The following command allows to build the test machine configuration:

.. code:: shell

   nix-build --argstr system x86_64-linux \
       '<nixpkgs/nixos>' \
       -A system \
       -I nixos-config=./test-machine.nix \
       --show-trace


.. Links


.. _NixOS: https://nixos.org/nixos

.. _container: https://nixos.org/nixos/manual/index.html#ch-containers
