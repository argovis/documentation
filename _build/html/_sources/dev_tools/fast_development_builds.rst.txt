.. _fast_angular_builds:

Fast Angular Builds
===================

Building the angular frontend container can be slow, which is an impediment to rapid iteration and development. Instead of building from scratch, Angular can be set to watch files as they change, and perform *incremental rebuilds* which are much faster. Follow the steps below to set this up.

1. Start up a local version of Argovis, as described in :ref:`setup_argovis`.

2. Identify the container network your containers are connected to, as described in :ref:`simple_container_connection`.

3. In your terminal, move to the root of your ``argovisNg`` directory.

4. In ``environments/environments.ts``, change ``ARGOVIS_API_ROOT`` to ``http://127.0.0.1:8080``.

5. Launch a development environment for Argovis, making sure to sub in the name of the network you just found and a recent tag of the ``argovis/ng`` image:

   .. code:: bash

      argovisNg $ docker container run \
          -v $(pwd)/src:/usr/src/ng_argovis/src \
          --network <argovis network name> \
          -p 3001:3000 \
          -d argovis/ng:dev

For the curious, these flags are:

 - ``-v $(pwd)/src:/usr/src/ng_argovis/src``: mount the directory that you're currently in (the root of your ``argovisNg``) to where that code is supposed to live in the argovisNg web frontend container.
 - ``--network <argovis network name>``: attach this container to the same network as the running version of the app (so it can access the mongodb database).
 - ``-p 3001:3000``: make this development version available at ``localhost:3001``.

6. After starting the container, a long string will be returned to the terminal. This is the container ID for the container you just started. Use the first few characters to run the Angular auto-rebuilder inside this container:

   .. code:: bash

      argovisNg $ docker container exec -it <container ID> ng build --watch=true

This takes several minutes to spin up, but you only need to do it once; once it's done starting, it'll look like:

   .. code:: bash

      chunk {ext-js-wasm-wasm-test-pkg-wasm_test} ext-js-wasm-wasm-test-pkg-wasm_test.js, b2c7ea01ec0169037ab2.module.wasm, ext-js-wasm-wasm-test-pkg-wasm_test.js.map (ext-js-wasm-wasm-test-pkg-wasm_test) 2.82 kB  [rendered]
      chunk {main} main.js, main.js.map (main) 1.7 MB [initial] [rendered]
      chunk {polyfills} polyfills.js, polyfills.js.map (polyfills) 721 kB [initial] [rendered]
      chunk {polyfills-es5} polyfills-es5.js, polyfills-es5.js.map (polyfills-es5) 794 kB [initial] [rendered]
      chunk {runtime} runtime.js, runtime.js.map (runtime) 11.2 kB [entry] [rendered]
      chunk {scripts} scripts.js, scripts.js.map (scripts) 535 kB [entry] [rendered]
      chunk {styles} styles.js, styles.js.map (styles) 690 kB [initial] [rendered]
      chunk {vendor} vendor.js, vendor.js.map (vendor) 21.2 MB [initial] [rendered]
      Date: 2021-09-12T05:46:01.476Z - Hash: 907431edfbafdcca7fbc - Time: 102955ms

Leave this terminal tab alone while you work. From here, changing any file in the ``argovisNg`` source directory you mounted into your development container will automatically trigger a partial build when you save the changes to disk. In the terminal running your builder, each change build will be reported similarly to:

   .. code:: bash

      Date: 2021-09-12T05:50:10.507Z - Hash: 0e05156071c776093206
      7 unchanged chunks
      chunk {main} main.js, main.js.map (main) 1.7 MB [initial] [rendered]
      Time: 5544ms 

Remember - the version you're editing is being served at ``http://localhost:3001``.

7. When you're done for the day:

   - hit ``CTRL+C`` in the tab running the auto builder to kill it, and tear down the app with ``docker-compose down`` as usual
   - revert the change you made in ``environments/environment.ts``
   - Do a regular build per the instructions in :ref:`building_dev_versions` to confirm things still look good after a full build. 

*Last reviewed --*
