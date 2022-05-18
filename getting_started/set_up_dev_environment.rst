.. _setup_argovis:

Setting Up Argovis
==================

In this tutorial, you'll learn how to deploy a toy version of Argovis to your laptop or development environment, so you can experiment with how it works and try modifying the codebase. In order to follow this tutorial, you'll need:

- A linux or OSX environment with:
   - a bash shell
   - docker
   - docker-compose
   - git

Quickstart Setup
----------------

1. Make a directory to store all your Argovis assets. We'll put this in our home directory, but you can put it anywhere you like:

   .. code:: bash

      ~$ mkdir ~/argovis

      ~$ cd ~/argovis

2. Make a directory to hold your database files:

   .. code:: bash

      argovis $ mkdir data

You'll need the absoute path to this directory in a later step; find it and note it down now before returning to the ``~/argovis`` directory:

   .. code:: bash

      argovis $ cd data

      data $ pwd
      
      data $ cd ..

For example, my absolute path returned by ``pwd`` was ``/Users/billmills/argovis/data``.

3. Download the minimal code necessary to start up Argovis:

   .. code:: bash

      argovis $ git clone -b main https://github.com/argovis/argovis_deployment

      argovis $ cd argovis_deployment

4. Before we launch the app, we need to tell it where to look for the data directory you made above. In your text editor of choice, open up ``docker-compose.yml`` and look for the lines describing the database volume mount, near the middle, which look like:

   .. code:: bash

      volumes:
        - /storage/mongodb:/data/db:Z

Change ``/storage/mongodb`` to the absolute path to your ``data`` directory you found above, in my case ``/Users/billmills/argovis/data``.

5. Start Argovis:

   .. code:: bash

      argovis_deployment $ docker-compose up -d

After a few seconds, visit ``http://localhost:3000`` in your web browser; you should see your very own local version of Argovis.

6. The first time you create Argovis on your machine (or if you ever change or delete the ``data`` directory mounted above), you'll need to inject an API key into the database that your dev version can use to access the API. Connect to the database you have running:

   .. code:: bash

      argovis_deployment $ docker container exec -it argovis_deployment_database_1 mongo

7. From this mongo shell, insert an API token ``guest`` into the ``argo`` database, ``user`` collection:

   .. code:: bash

      > use argo
      > db.user.insertOne({"key": "guest", "tokenValid": 1})
      > exit

8. Once you're satisfied all is well, tear your local deployment down:

   .. code:: bash

      argovis_deployment $ docker-compose down

.. _startup_load_test_data:

Loading Data
------------

The version of Argovis you have up and running from the previous section works, but has no actual data loaded in it. In this section we'll see how to fetch and load some Argo float data so there's something to look at in our development environment.

The FTP server at ftp://ftp.ifremer.fr/ifremer/argo contains all the Argo profile data used by the database. Getting the data into the database involves downloading files and directories to argo. We will use the rsync utility to download a few profiles, and use the argo-database repository to convert these files to entries on the server.

1. Start your development version of argovis back up if you tore it down at the end of the last section:

   .. code:: bash

      ~$ cd ~/argovis/argovis_deployment

      argovis_deployment $ docker-compose up -d

2. Return to the directory containing all your Argovis assets, and clone the Argovis database management code:

   .. code:: bash

      ~$ cd ~/argovis

      argovis $ git clone -b dev https://github.com/argovis/argo-database
      
      argovis $ cd argo-database


3. Make a directory to hold some demo profiles:

   .. code:: bash

      argo-database $ mkdir -p profiles/aoml

4. Use ``rsync`` to fetch some profiles:

   .. code:: bash

      argo-database $ rsync -arvzhim --delete \
          --include='**/' \
          --include='**/profiles/[RDM]*.nc' \
          --exclude='*' \
          --exclude='**/profiles/B*' \
          vdmzrs.ifremer.fr::argo/aoml/4902911 ./profiles/aoml

All the profiles from the float 4902911 should have been written to ``argo-database/profiles/aoml/4902911/profiles``. You can add more or all of the floats in this fashion if you wish.

5. In order to simplify environment setup, we'll run our database update script from a containerized environment that has all the tooling you'll need pre-installed. Start and connect to this contianerized environment from the ``argo-database`` directory:

   .. code:: bash

      argo-database $ docker container run \
          -u $(id -u):$(id -g) \
          -it --rm --net=host \
          -v $(pwd):/usr/src/argo-database/:Z \
          argovis/argo-db:tut bash

6. Move to the appropriate directory in the container's filesystem, run the data upload script, and exit the contianerized environment when complete:

   .. code:: bash

      argo-database $ cd add-profiles

      add-profiles $ python add_profiles.py \
          --mirrorDir /usr/src/argo-database/profiles \
          --logName tutorial.log

      add-profiles $ exit

7. In your browser, visit your deployment of Argovis at ``http://localhost:3000``, and use the search box in the left sidebar to search for float 4902911; if all is well, you should see this float's data populated on the map.

.. _building_dev_versions:

Building Dev Versions
---------------------

So far, we've relied on pre-built container images for Argovis to get things stood up and working quickly. But, of course you'll want to build your code into new containers and try them out as part of your local deployment. We'll learn how to do that in this section.
 
1. There are four component you can build in Argovis:

 - The API: https://github.com/argovis/argovis_api
 - The Angular frontend: https://github.com/argovis/argovisNg
 - The datapages addon: https://github.com/argovis/datapages
 - The redis kv store: https://github.com/argovis/argovis_redis

Each of these repositories has instructions in the README for building development container images. Follow the instructions for the one you want to build; for the rest of this example, we'll assume you built a new Angular frontend image and called it ``argovis/ng:dev``.

2. Open up ``argovis_deployment/docker-compose.yaml``, and change the appropriate image name to the development image you just created. So for our example, we'd change the ``image`` key under ``ng`` to be ``image: argovis/ng:dev``.

3. Tear down your current local version, if running, with ``docker-compose down`` from the ``argovis_deployment`` directory.

4. Stand up Argovis with your new container:

   .. code:: bash

      argovis_deployment $ docker-compose up -d

Argovis should be available after a moment in your browser at ``localhost:3000``, using your new dev container.

*Last reviewed --*
