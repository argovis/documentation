.. argovis documentation master file, created by
   sphinx-quickstart on Wed Sep  8 04:33:12 2021.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Argovis Documentation
=====================

Welcome to the documentation for the Argovis project! These docs are meant to provide details and context for devops engineers maintaining and expanding Argovis. If you're an enduser of Argovis, you will probably get more use out of our example notebooks at `https://github.com/argovis/demo_notebooks <https://github.com/argovis/demo_notebooks>`_.

Like Argovis, these docs contain three main sections, describing devops and disaster recovery for our database, API, and frontend respectively. Ops guidance is provided in the operations playbooks section, and in the appendix you'll find some notes and Q&A that we collected over time. **A new Argovis engineer should read the numbered sections thoroughly.** They are intended as a guide to convey the complete mental model of how the application is architected and how it is maintained.

Argovis engineering at a glance
-------------------------------

Argovis is architected as a three-tier web app:

 - **MongoDB** serves our database.
 - An **OpenAPI**-compliant description of `our API <https://github.com/argovis/argovis_api>`_ is used to generate and structure a **NodeJS**-based public API.
 - A `React app <https://github.com/argovis/react>`_ consumes our public API to provide an `interactive frontend <https://argovis.colorado.edu/>`_.

Numerous other supporting components exist, but these three form the bulk of the business logic.

All Argovis software is containerized, and orchestrated preferably on Kubernetes, or on Docker Swarm as a fallback. `Deployment manifests <https://github.com/argovis/argovis_deployment>`_ are avilable for both and will be discussed in detail in the relevant sections below.

In addition to this software stack, Argovis also develops and maintains a generic schema for oceanographic data, described in the :ref:`schema`. This JSON representation is meant to provide a data format that can provide enough flexibility to represent a wide variety of oceanographic data while imposing as much standardization as makes sense, as well as to provide a data format that balances ease of use with efficiency of communication.

Documentation conventions
-------------------------

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

Table of contents
-----------------

.. toctree::
   :maxdepth: 2
   :caption: 0. Welcome

   index.rst

.. toctree::
   :maxdepth: 2
   :caption: 1. Data & Database

   database/getting_started
   database/schema
   database/db_ops
   database/adding_new_data
   database/argo

.. toctree::
   :maxdepth: 2
   :caption: 2. API

   api/getting_started
   api/adding_new_endpoints
   api/rate_limitation
   api/ops_config
   api/hit_logging

.. toctree::
   :maxdepth: 2
   :caption: 3. Frontend

.. toctree::
   :maxdepth: 2
   :caption: 4. Deployment & operations

   ops/deployment
   ops/drifters-aws

.. toctree::
   :maxdepth: 2
   :caption: Appendix: Archival Notes

   special_topics/intro
   special_topics/pull_requests_and_github
   special_topics/merge_conflicts
   special_topics/using_branches
   special_topics/connecting_to_the_container_network
   special_topics/goship-demo
   special_topics/api_usage
   special_topics/performance_testing