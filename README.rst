
===========================================================
 Adjusted Nix derivations to build Rhodecode Enterprise CE
===========================================================


Purpose
=======

This repository is my personal experimentation area to figure out how to build
the community edition of `RhodeCode Enterprise`_ with the package manager Nix_.
My intention is to run an instance of `RhodeCode Enterprise`_ as a NixOS_
service.


Status
======

In both cases `nix-build` is able to produce a result on darwin so far.



Next things to be done
======================

* Test on NixOS_

* Create a simple service module

* Try a deployment, e.g. based on NixOPS_

* Improve service modules to initialize on the first run



Contact
=======

I plan to maintain reasonable ways to contact myself at https://www.johbo.com.
In terms of these files, fell free to open issues or pull requests as it suits
you best.



.. Links:

.. _RhodeCode Enterprise: https://code.rhodecode.com/rhodecode-enterprise-ce

.. _RhodeCode VCSServer: https://code.rhodecode.com/rhodecode-vcsserver

.. _Nix: https://nixos.org/nix

.. _NixOS: https://nixos.org/nixos

.. _NixOPS: https://nixos.org/nixops
