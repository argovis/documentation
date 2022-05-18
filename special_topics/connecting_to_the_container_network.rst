Connecting to the Container Network
===================================

When you launch Argovis, docker-compose makes a container network that all the application containers can communicate over. There are some instances when you might want to attach a new container to the existing network:

 - You have an experimental version of the web app or API, and want it to be able to communicate with your existing mongodb container instance.
 - You have some containerized tooling, like diagnostic or performance tools, that you'd like to network to your existing deployment.
 - Many others.

 In this tutorial, you'll learn two ways to attach a new container to an existing container network. We assume you have argovis up and running before beginning.

.. _simple_container_connection:

Method 1: Simple Container
--------------------------

1. Suppose you want to connect a new container to your mongodb container. Start by listing your containers to get the ID of your mongodb container:

   .. code:: bash

      ~ $ docker container ls

          CONTAINER ID   IMAGE        ...
          c5f477eb4a83   mongo:4.2.3  ...

2. Inspect your container; you're looking for the ``Networks`` block at the bottom:

   .. code:: bash

      ~ $ docker container inspect <mongo container ID>

            ...
            "Networks": {
                "argovisng_default": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": [
                        "database",
                        "c5f477eb4a83"
                    ],
                    "NetworkID": "9a6079f99776c7470b1f302cfc88a3b73461b4f881546439e101966b7e773665",
                    "EndpointID": "5fd8da86a46f1c351299f4e91c3d05f76405dbd5e60d1b145bde38163bc0ee5d",
                    "Gateway": "172.18.0.1",
                    "IPAddress": "172.18.0.2",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "MacAddress": "02:42:ac:12:00:02",
                    "DriverOpts": null
                }
            }

The name of the network your mongodb container is attached to is the very first key: ``argovisng_default`` in this case. You might have noticed docker-compose create this network when you first stood up your application.

3. Launch a container attached to this network. You can use any container image you like, but for this simple example we'll just make another copy of argovis' web tier, and show that it's communicating with the database:

   .. code:: bash

      ~ $ docker container run -d --network argovisng_default \
          -p 3040:3000 argovis/ng:dev 

At this point you should be able to visit this new copy of Argovis on port 3040, and search for some data, showing that it is successfully connected to your database container. Of course, you'll be using a different container image to suit your purposes, but the syntax for connecting to the correct container network is the same.

*Last reviewed --*