.. argovis documentation master file, created by
   sphinx-quickstart on Wed Sep  8 04:33:12 2021.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Argovis Documentation
=====================

Welcome to the documentation for the Argovis project!

Conventions
-----------

We follow the following conventions in these docs:

Code prompts
++++++++++++

Unless otherwise noted, all terminal commands are *bash shell commands*.

Prompts indicate the directory the command is expected to be run from, and are delimited with a ``$`` character. So:

.. code:: bash

   documentation $ pwd

indicates you're expected to run the ``pwd`` command in the ``documentation`` directory. Note that only the 'nearest' directory level is noted in this way, for brevity; the ``documentation`` directory in the above example might in fact be at ``/Users/lovelace/projects/documentation`` on your machine, but we hope this will be clear from context in each article.

Per the typical convention, we use ``~`` in this context to indicate your home directory. 

Variables
+++++++++

When a command includes a variable we expect you to substitute in, it will appear in ``<angle brackets>``. Replace the token, *including the angle brackets*, with the value. So a command like:

.. code:: bash
   
   ~ $ docker container inspect <container ID>

Might actually look like:

.. code:: bash

   ~ $ docker container inspect a508e35206a9

Contributing
------------

We enthusiastically welcome contributions via pull request to the documentation `on GitHub <https://github.com/argovis/documentation>`_. Follow these steps to get set up contributing documentation:

0. Before investing a lot of your time writing docs, `open an issue in the docs repo <https://github.com/argovis/documentation/issues>`_ to discuss your idea or request with the team, so we can make sure it's a good fit for the project and no one else is already working on it.

1. Make sure you have installed on your development machine:

 - git
 - docker
 - a bash shell

You'll also need a free GitHub account.

2. Fork https://github.com/argovis/documentation on GitHub to your own account.

3. Clone your fork of the documentation repo to your local machine.

4. Try building the docs as is:

.. code:: bash

   ~ $ cd documentation
   documentation $ docker container run -it -v $(pwd):/src argovis/docbuilder:dev make html

If all is well, open ``documentation/_build/html/index.html`` in your browser to see your locally-built version of the docs.

.. admonition:: Warning

   When you rebuild the docs in future, make sure your ``_build`` directory is empty! Otherwise, pre-existing pages may not get rebuilt, and their nav sidebar will be out of date.

5. From here, you're set up and ready to start creating your documentation. When you're done, commit your code, push it back to your fork on GitHub, and open a pull request.

.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   getting_started/set_up_dev_environment
   getting_started/api_development
   getting_started/custom_angular_components

.. toctree::
   :maxdepth: 2
   :caption: Operations Playbooks

   ops/deployment
   ops/performance_testing

.. toctree::
   :maxdepth: 2
   :caption: Developer Playbooks

   dev/adding_query_parameter

.. toctree::
   :maxdepth: 2
   :caption: Data Management

   data_management/api_usage
   data_management/schema
   data_management/serving_a_new_dataset
   data_management/argo_merge

.. toctree::
   :maxdepth: 2
   :caption: Developer Tools & Techniques

   dev_tools/fast_development_builds
   dev_tools/pull_requests_and_github
   dev_tools/merge_conflicts
   dev_tools/using_branches

.. toctree::
   :maxdepth: 2
   :caption: Disaster Recovery

   disaster_recovery/rebuild_mongo_from_scratch
   disaster_recovery/restore_a_mongo_collection
   disaster_recovery/restore_from_ami

.. toctree::
   :maxdepth: 2
   :caption: Special Topics

   special_topics/connecting_to_the_container_network
   special_topics/goship-demo