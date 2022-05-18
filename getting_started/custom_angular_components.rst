Creating Custom Angular Components
==================================

The great strength of Angular as a web framework is its orientation towards *modularization*: all parts of a website can be described as self-contained custom components. Angular provides tooling for generating boilerplate to start creating your own components, but integrating that into an existing application requires careful version matching between development and production environments. In this tutorial, you'll learn how to use Argovis' containerized environment to generate custom components that are guaranteed to build successfully.

1. In the ``argovisNg`` directory on your development machine, as always start by updating your ``main`` branch to make sure you have the latest code, and create a feature branch to do your new work on:

   .. code:: bash

      argovisNg $ git checkout main

      argovisNg $ git pull upstream main

      argovisNg $ git checkout -b my-custom-component

2. Build the ``argovisNg`` image, in order to capture the latest environment for this app:

   .. code:: bash

      argovisNg $ docker image build -t argovisNg:buildenv .

3. Start the ``argovisNg`` container as an interactive environment, and mount your ``argovisNg`` directory from your computer into the container's filesystem at ``/ngdev``:

   .. code:: bash

      argovisNg $ docker container run -v $(pwd):/ngdev --rm -it argovisNg:buildenv bash

4. Navigate to ``/ngdev`` inside the container, use the angular tools to generate your component boilerplate, and exit the container once finished:

   .. code:: bash

      root@...# cd /ngdev

      root@...:/ngdev# ng generate component profview/democomponent

      root@...:/ngdev# exit

5. [optional] Check to make sure the boilerplate files you created aren't owned by root:

   .. code:: bash

      argovisNg $ ls -lsh src/app/profview/democomponent

   If the owner and group are ``root root``, which they might be particularly on a linux machine, change them to your ownership with ``sudo chown $USER:$USER``.

6. Build your image again to make sure everything compiles with the new component inserted in:

   .. code:: bash

      argovisNg $ docker image build -t argovisNg:buildtest .

.. admonition:: Do I have to do this inside the container?

   It's possible to set up an uncontainerized dev environment that matches your containerized environment, allowing you to do ``ng generate component`` directly on your development environment - but this requires matching a potentially complex stack of dependencies between the two, and managing those changes on your development machine as the application evolves. By doing this inside the container, we are guaranteed to match our running environment *exactly*, every time, without managing stacks of dependencies manually.

*Last reviewed --*