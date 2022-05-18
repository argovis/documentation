API Development
===============

Argovis delivers a standalone API meant to act as a dedicated broker between our database on the one side, and both users and applications on the other. In this article, you'll learn about the basic architecture of our API, and how to set up for development. The code for our API lives in `this GitHub repo <https://github.com/argovis/argovis_api>`_.

In order to follow the instructions in this article, you will need a single development machine with:

 - x86-arch processor
 - a bash shell (available by default on OSX and linux, and accessible on Windows 10 via the Linux Subsystem)
 - Docker installed
 - git installed

If you're running Docker in a VM (as is the case for Docker Desktop on Mac), make sure you allocate at least 8 GB RAM to the VM. More is always better.

Architecture
------------

Argovis' API is a nodejs-based, OpenAPI v3.03 compliant REST API. It is served in Docker containers, with an inter-container architecture that looks like:

.. image:: ../images/apiApplicationArch.png

The reponsibilities of each container and connection are:

 - an off-the-shelf containerized version of mongodb holds all our raw data.
 - argovis_api runs in its own container; in production, this is the only container allowed to communicate with mongodb, and the only container users on the web are allowed to communicate with. All requests must proceed through the API container.
 - a redis database with some custom config is used by the API to keep track of API requests, and throttle users that issue fast requests that threaten to swamp the database or network.

.. _api_dev_env:

Setting Up a Working Dev Environment
------------------------------------

In order to set up an effective development environment, we need to set up the mongodb and redis containers, build and set up the API container, and populate the mongo db instance with test data.

1. Visit `https://github.com/argovis/argovis_api <https://github.com/argovis/argovis_api>`_ and fork the repository to your own GitHub account. If you're new to Git and GitHub, see the walkthrough of how the Argovis team collaborates on GitHub starting with :ref:`prs`.

2. Create a directory structure to hold all the assets required and clone the API code; don't forget to change ``<Your User Name>`` to your GitHub username.

   .. code:: bash

      ~ $ mkdir ~/apidev ; cd ~/apidev

      apidev $ mkdir db ; mkdir raw ; mkdir raw/RG

      apidev $ git clone https://github.com/<Your User Name>/argovis_api

      apidev $ cd argovis_api

      argovis_api $ git remote add upstream https://github.com/argovis/argovis_api

      argovis_api $ git fetch upstream

      argovis_api $ cd ..

   That ``db`` directory is where we'll mount our mongodb data, and the ``raw`` directory is where we'll store raw data for loading into the database later.

3. Create a network for all your containers to interact on:

   .. code:: bash

      apidev $ docker network create apinet

4. Set up mongodb and redis:

   .. code:: bash

      apidev $ docker container run -p 127.0.0.1:27017:27017 --network apinet -v $(pwd)/db:/data/db -d --name database mongo:5.0.6

      apidev $ docker container run -d --network apinet --name redis argovis/redis:6.2.6-220415

5. Set up an API token for use during development:

   .. code:: bash

      apidev $ docker container exec -it database mongo

      > use argo
      > db.user.insertOne({key: "developer", tokenValid: 9999})
      > exit

6. Build the API container from source, and start it running:

   .. code:: bash

      apidev $ docker image build -t argovisapi:dev argovis_api

      apidev $ docker container run -d -p 8080:8080 --network apinet --name api argovisapi:dev

7. Everything is now up and running; do ``docker container ls`` to confirm you have three containers running, named ``database``, ``redis`` and ``api``.

8. Access an API endpoint like so:

   .. code:: console

      apidev $ curl -H "x-argokey: developer" localhost:8080/grids?gridName=rgTempTotal

At this point you should recieve a 404 reponse for every request, since there's no data loaded in the database yet. See :ref:`api_load_test_data` for guidance on loading some test data, or the next section on how to build new code into the API.

Teardown
++++++++

If you need to tear down your dev environment completely and start over, run the following:

.. code:: bash

   ~ $ docker container rm -f api redis database
   ~ $ docker network rm apinet

This will remove everything except the contents of mongodb, which have been saved to disk outside your containers. If you repeat the setup instructions, you'll have a fresh environment with the previous content of mongodb restored. If you also want to reset all the contents of mongodb, remove everything in ``~/apidev/db``.

Code Repository Structure & Development Workflow
------------------------------------------------

Argovis' API is developed in a *specification-first* manner with the following workflow: 

 - any new endpoints or schema changes are first made in the specification document, which is an `OpenAPI v3.03 spec doc as described here <https://swagger.io/specification/>`_.
 - server-side code templates are automatically generated based on this spec.
 - business logic of each endpoint is then implemented in the auto-generated templates.

Code is managed in `this GitHub repo <https://github.com/argovis/argovis_api>`_, which has two branches:

 - ``templates``, which holds the OpenAPI specification of our API in the top level ``spec.json`` and the auto-generated templates of our server logic
 - ``server``, which holds the templates of our server logic with the actual code filled in.

See the next two subsections for standard workflows when developing for this API.

.. _api_business_logic:

Development Workflow: Logic Changes Only
++++++++++++++++++++++++++++++++++++++++

If the changes you want to make:

 - Do not change, add or remove any route paths
 - Do not change, add or remove any query string parameters
 - Do not change, add or remove any return schema
 - But *do* change how the API queries, filters and sorts data from mongodb,

Then follow these steps in your development workflow:

1. Make sure you're in the ``arogvis_api`` directory, on the ``server`` branch, and have the latest version of the server code:

   .. code:: bash 

      ~ $ cd ~/apidev/argovis_api

      argovis_api $ git checkout server

      argovis_api $ git pull upstream server

2. Make any modification you like to the server logic, typically what's found in ``nodejs-server/controllers``, ``nodejs-server/helpers`` and / or ``nodejs-server/service``. If you want to change ``spec.json``, you're in the wrong workflow; see :ref:`api_route_schema` for those changes.

3. Build your new version of the api container:

   .. code:: bash

      argovis_api $ docker image build -t argovisapi:dev .

4. [Optional] If you have a development version of the API running per :ref:`api_dev_env`, remove the running API container:

   .. code:: bash

      argovis_api $ docker container rm -f api

5. Run your new version of the API:

   .. code:: bash

      argovis_api $ docker container run -d -p 8080:8080 --network apinet --name api argovisapi:dev

   At this point, your new version should be up and running, and you can query it at ``localhost:8080``.


.. _api_route_schema:

Development Workflow: Route and Schema Changes
++++++++++++++++++++++++++++++++++++++++++++++

If the changes you want to make affect the API specification or input or return schema in any way, use the following workflow. You'll see it involves two branches: we edit our spec and make the new templates on the ``templates``  branch, which only contains the spec and auto-generated templates, then we merge that into the ``server`` branch before creating the specific business logic.

1. Make sure you're in the ``arogvis_api`` directory, and have the latest version of the server and template code:

   .. code:: bash 

      ~ $ cd ~/apidev/argovis_api

      argovis_api $ git checkout server

      argovis_api $ git pull upstream server

      argovis_api $ git checkout templates

      argovis_api $ git pull upstream templates

2. While on the ``templates`` branch, the *only* file you should change by hand is ``spec.json``. Make the changes to the routes and schema you desire now.

3. Build the templates from your new schema:

   .. code:: bash

      argovis_api $ docker container run --rm -v ${PWD}:/local \
                        swaggerapi/swagger-codegen-cli-v3 generate \
                        -i /local/spec.json \
                        -l nodejs-server \
                        -o /local/nodejs-server

4. Commit your new templates:

   .. code:: bash

      argovis_api $ git commit -a -m 'my new api spec templates'

5. Check out the ``server`` branch, and merge in your new templates:

   .. code:: bash

      argovis_api $ git checkout server
      argovis_api $ git merge templates

.. admonition:: Merge Conflict?

   This is a common place to get a merge conflict. The autogenerated templates include some examples of valid input and output schema which are well-intentioned but generally not helpful. When resolving the conflict, delete these and keep the custom code from the ``server`` branch. If you need more guidance on resolving merge conflicts, see :ref:`merge_conflict` for a recipe for dealing with this.

At this point, you're ready to start writing or updating the business logic of the routes you modified. Follow the instructions starting at step 2 of :ref:`api_route_schema`.

Submitting Code
+++++++++++++++

Once you finish and your code edits, do the following to make sure you're ready to submit changes:

1. Make sure tests still pass on the ``server`` branch. See the file ``.travis.yml`` on the ``server`` branch and do the steps outlined in the ``script`` section in your ``argovis_api`` directory. All tests *must* pass before any PR will be accepted.

2. Once tests are passing, push both ``templates`` and ``server`` to your fork on GitHub, and make a PR for each if you changed them. If you need some guidance on how to do this, see :ref:`prs`.
 
.. _api_load_test_data:

Loading Test Data
-----------------

In order to get interesting results back from the API in development, you'll need to load some data into your mongodb instance. Choose the section below that's most relevant to the section of the API you're working on.

Profile Data
++++++++++++

See :ref:`startup_load_test_data`.

Gridded Data
++++++++++++

In order to experiment with the gridded product API endpoints, the following will load the Roemmich-Gilson Argo Climatology total temperature grid into your local mongo.

1. Get, build and run the script that defines the collection and schema in mongodb:

   .. code:: bash

      ~ # cd ~/apidev

      apidev $ git clone https://github.com/argovis/db-schema

      apidev $ cd db-schema

      apidev $ docker image build -t dbschema .

      apidev $ docker container run --network apinet  dbschema python grids-meta.py

      apidev $ docker container run --network apinet  dbschema python grids.py rgTempTotal

2. Download the RG temperature climatology files from https://sio-argo.ucsd.edu/RG_Climatology.html, place them in ``~/apidev/raw/RG``, and unzip them.

3. Download the grid loading scripts:

   .. code:: bash

      ~ # cd ~/apidev

      apidev $ git clone https://github.com/argovis/grid-sync

4. Build and run:

   .. code:: bash

      ~ # cd ~/apidev

      apidev $ docker image build -t gridload grid-sync

      apidev $ docker container run --name loadrg --network apinet -d -v <absolute path to ~/apidev/raw/RG>:/tmp/rg gridload python translate-rg-grid.py temp total

This will take a long time to load the entire grid; once ``curl -H "x-argokey: developer" localhost:8080/grids?gridName=rgTempTotal`` starts returning real results, it's safe to kill the grid loading script with ``docker container rm -f loadrg``, or just let it run in the background to populate the entire grid.


*Last reviewed 22-05-17*
