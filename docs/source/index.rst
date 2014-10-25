.. Halite (Prototype) documentation master file, created by
   sphinx-quickstart on Fri Oct 24 23:11:12 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to Halite's dev documentation!
==================================================

Some functionality offered by Halite:

* Execution of Salt module functions and ability to show docs for these functions
* Generic display of Salt job return data
* Exposes your Salt data like minions, jobs, commands and events. This data can be helpful when developing customizations and components that need Salt related data. Note: All Salt related data is handled by the `app data service (appDataSrvc)
  <https://github.com/saltstack/halite/blob/07fd17d321e7ba1b9663f1fd72c8d9bd3167cd59/halite/lattice/app/util/appDataSrvc.coffee>`_.


Contents:

.. toctree::
   :maxdepth: 2

   dev_setup
   example_module_exec


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

