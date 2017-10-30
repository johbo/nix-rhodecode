
==============================
 Generate the Nix expressions
==============================


Start the environment as follows:

.. code:: shell

   nix-shell shell-generate.nix


And make sure to have a symlink to the sources available:

.. code:: shell

   ln -s ../../rhodecode-vcsserver src



Python dependencies
===================

.. code:: shell

   pip2nix generate --licenses



.. Links

.. _RhodeCode VCSServer: https://code.rhodecode.com/rhodecode-vcsserver
