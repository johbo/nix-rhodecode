
==============================
 Generate the Nix expressions
==============================

Details can be found in the repository of `RhodeCode Enterprise CE`_ inside of
the file `docs/contributing/dependencies.rst`.

Start the environment as follows:

.. code:: shell

   nix-shell shell-generate.nix


And make sure to have a symlink to the sources available:

.. code:: shell

   ln -s ../../rhodecode-enterprise-ce src



Python dependencies
===================

.. code:: shell

   pip2nix generate --licenses



NodeJS dependencies
===================

.. code:: shell

   cd pkgs
   node2nix --input ../src/package.json \
            -o node-packages.nix \
            -e node-env.nix \
            -c node-default.nix \
            -d --flatten



Bower dependencies
==================

.. code:: shell

   bower2nix bower.json pkgs/bower-packages.nix



Notes
=====

I did have to tweak the requirements files a bit, so that I currently include a
copy of the modified files in here.



.. Links

.. _RhodeCode Enterprise CE: https://code.rhodecode.com/rhodecode-enterprise-ce
